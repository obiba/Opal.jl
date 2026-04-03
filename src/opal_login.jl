function _url(opal, args...)
    parts = filter(x -> x != "", collect(args))
    encoded_parts = map(escapepath, parts)
    full_url = join([opal.url, "ws", encoded_parts...], "/")
    return replace(full_url, r"(?<!:)//+" => "/")
end

function _authorizationHeader(username, password)
    return "X-Opal-Auth " * base64encode("$username:$password")
end

function _tokenHeader(token)
    return token
end

abstract type AbstractAuthStrategy end
struct UserPasswordAuth <: AbstractAuthStrategy
    username::String
    password::String
end

struct TokenAuth <: AbstractAuthStrategy
    token::String
end

struct SSLAuth <: AbstractAuthStrategy
    sslcert::String
    sslkey::String
end

function authenticate!(opal, strategy::UserPasswordAuth)
    opal.authorization = _authorizationHeader(strategy.username, strategy.password)
end

function authenticate!(opal, strategy::TokenAuth)
    opal.token = _tokenHeader(strategy.token)
end

function authenticate!(opal, strategy::SSLAuth)
    if haskey(opal.config, "cainfo")
        opal.config["cainfo"] = _getPEMFilePath(opal.config["cainfo"])
    end
    opal.config["sslcert"] = _getPEMFilePath(strategy.sslcert)
    opal.config["sslkey"] = _getPEMFilePath(strategy.sslkey)
end

"""
    opal_login() -> OpalConnection

Logs into an Opal server and returns an OpalConnection object.

# Arguments
- `username::Union{String, Nothing}=nothing`: User name in opal
- `password::Union{String, Nothing}=nothing`: User password in opal
- `token::Union{String, Nothing}=nothing`: Personal access token (since opal 2.15)
- `url::Union{String, Nothing}=nothing`: Opal url. Secure http (https) connection is required.
- `opts::Dict=Dict()`: Curl options
- `profile=nothing`: R server profile name. This will drive the R server in which a R session will be created. If no remote R session is needed (because Opal specific operations are done), this parameter does not need to be provided. Otherwise, if missing, the default R server profile will be applied ('default').
- `restore=nothing`: Workspace ID to be restored
- `context="r"`: Context of the R session to be created. Either "r" (default) or "datashield".
"""
#TODO: account for url being a vector of urls
function opal_login(;
    username::Union{String,Nothing}=nothing,
    password::Union{String,Nothing}=nothing,
    token::Union{String,Nothing}=nothing,
    url::Union{String,Nothing}=nothing,
    opts::Dict=Dict(),
    profile=nothing,
    restore=nothing,
    context::String="r",
)
    return _opal_login(;
        username=username,
        password=password,
        token=token,
        url=url,
        opts=opts,
        profile=profile,
        restore=restore,
        context=context,
    )
end

function _opal_login(;
    username::Union{String,Nothing}=nothing,
    password::Union{String,Nothing}=nothing,
    token::Union{String,Nothing}=nothing,
    url::Union{String,Nothing}=nothing,
    opts::Dict=Dict(),
    profile=nothing,
    restore=nothing,
    context::String="r",
)
    if context ∉ ("r", "datashield")
        throw(ArgumentError("R session type must be either 'r' or 'datashield'"))
    end

    if isnothing(url)
        throw(ArgumentError("opal url is required"))
    end

    opalUrl = url
    if startswith(url, "http://localhost:")
        @warn "Connecting through non-secure http"
    elseif startswith(url, "http://")
        throw(ErrorException("Connecting through secure http is required."))
    end

    urlObj = URI(opalUrl)

    opal = Dict{Symbol,Any}()
    opal = OpalObject()
    opal.username = username
    opal.url = rstrip(opalUrl, '/')
    opal.name = urlObj.host
    opal.version = missing
    opal.encoding = "UTF-8"
    if haskey(opts, "encoding")
        opal.encoding = opts["encoding"]
        delete!(opts, "encoding")
    end

    http_options = copy(opts)
    # legacy RCurl options to httr/HTTP.jl
    if haskey(http_options, "ssl.verifyhost")
        http_options["ssl_verifyhost"] = http_options["ssl.verifyhost"]
        delete!(http_options, "ssl.verifyhost")
    end
    if haskey(http_options, "ssl.verifypeer")
        http_options["require_ssl_verification"] = http_options["ssl.verifypeer"]
        delete!(http_options, "ssl.verifypeer")
    end

    if urlObj.host == "localhost"
        if !haskey(http_options, "ssl_verifyhost")
            # HTTP.jl does not have a direct equivalent for ssl_verifyhost=false
            # It's generally handled by require_ssl_verification
        end
        if !haskey(http_options, "require_ssl_verification")
            http_options["require_ssl_verification"] = false
        end
    end

    # authentication strategies
    opal.authorization = nothing
    opal.token = nothing
    strategy =
        if !isnothing(username) &&
            !isempty(username) &&
            !isnothing(password) &&
            !isempty(password)
            UserPasswordAuth(username, password)
        elseif !isnothing(token) && !isempty(token)
            TokenAuth(token)
        elseif haskey(http_options, "sslcert") && haskey(http_options, "sslkey")
            SSLAuth(http_options["sslcert"], http_options["sslkey"])
        else
            throw(
                ArgumentError(
                    "opal authentication strategy not identified: either provide username/password or API access token or SSL certificate/private keys",
                ),
            )
        end

    authenticate!(opal, strategy)

    opal.config = http_options
    opal.rid = nothing
    opal.restore = restore
    opal.profile = profile

    # get user profile to test sign-in
    profileUrl = _url(opal, "system", "subject-profile", "_current")

    headers = Dict()
    if !isnothing(opal.authorization)
        headers["Authorization"] = opal.authorization
    end
    if !isnothing(opal.token)
        headers["X-Opal-Auth"] = opal.token
    end

    r = try
        request("GET", profileUrl; headers=headers, opal.config...)
    catch e
        if isa(e, StatusError) && e.status == 401
            optHeader = header(e.response, "WWW-Authenticate", "")
            if optHeader == "X-Opal-TOTP" || optHeader == "X-Obiba-TOTP"
                print("Enter 6-digits code: ")
                code = readline()
                headers[optHeader] = code
                request(
                    "GET",
                    profileUrl;
                    headers=headers,
                    cookies=true,
                    cookiejar=cookiejar,
                    opal.config...,
                )
            else
                rethrow(e)
            end
        else
            rethrow(e)
        end
    end

    opal.uprofile = _handleResponse!(opal, r)
    # opal.username = opal.uprofile["principal"]

    # if get(opal.uprofile, "otpRequired", false)
    #     @warn "Enabling 2FA is required, connect to Opal web page to set up your secret."
    # end
    opal.context = context

    return opal
end
