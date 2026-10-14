"""
    opal_get(opal, args...; query=Dict(), acceptType="application/json", outFile=nothing, callback=nothing, retries=3)

Generic REST resource retrieval.

# Arguments
- `opal::OpalObject`: Opal object
- `args...`: Resource path segments
- `query::Dict{String,Any}=Dict{String,Any}()`: Named dictionary of query parameters
- `acceptType::String="application/json"`: The accept type of the response
- `outFile::Union{String,Nothing}=nothing`: Not supported; throws an error if not nothing (default)
- `callback::Union{Function,Nothing}=nothing`: A callback function to handle the response object
- `retries::Int=3`: Number of retries
"""
function opal_get(
    opal::OpalObject,
    args...;
    query::Dict{String,Any}=Dict{String,Any}(),
    acceptType::String="application/json",
    outFile::Union{String,Nothing}=nothing,
    callback::Union{Function,Nothing}=nothing,
    retries::Int=3,
)
    logerrors = false
    headers = Dict("Accept" => acceptType)

    # Add authorization headers
    if !isnothing(opal.authorization)
        headers["Authorization"] = opal.authorization
    end
    if !isnothing(opal.token)
        headers["X-Opal-Auth"] = opal.token
    end
    if !isnothing(opal.csrf)
        headers["X-XSRF-Token"] = opal.csrf
    end

    if !isnothing(outFile)
        throw(ErrorException("Downloading to file is not supported for GET requests."))
    end

    url = _url(opal, args...)
    r = request(
        "GET",
        url;
        query=query,
        headers=headers,
        logerrors=logerrors,
        status_exception=false,
        retry=true,
        retries=retries,
        _requestConfig(opal)...,
    )

    return _handleResponseOrCallback!(opal, r, callback)
end
