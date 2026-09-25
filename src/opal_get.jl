# TODO: investigate if we can use the terminate_on functionality in Julia.
# This would rely on passing a function to the retry_check kwarg
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
    r = nothing
    logerrors = false
    headers = Dict("Accept" => acceptType)

    if !isnothing(opal.csrf)
        headers["X-XSRF-Token"] = opal.csrf
    end

    url = _url(opal, args...)
    r = if isnothing(outFile)
        request(
            "GET",
            url;
            query=query,
            headers=headers,
            logerrors=logerrors,
            retry=true,
            retries=retries,
        )
    else
        throw(ErrorException("Downloading to file is not supported for GET requests."))
        open(outFile, "w") do io
            return HTTP.request(
                "GET",
                url;
                query=query,
                headers=headers,
                response_stream=io,
                logerrors=logerrors,
                retry=true,
                retries=retries,
            )
        end
    end

    return _handleResponseOrCallback!(opal, r, callback)
end
