"""
    opal_post(opal, args...; query=Dict(), body="", contentType="application/x-rscript", acceptType="application/json", outFile=nothing, callback=nothing)

Generic REST resource creation.

# Arguments
- `opal::OpalObject`: Opal object
- `args...`: Resource path segments
- `query::Dict{String,Any}=Dict{String,Any}()`: Named dictionary of query parameters
- `body::String=""`: The body of the request
- `contentType::String="application/x-rscript"`: The type of the body content
- `acceptType::String="application/json"`: The type of the body content
- `outFile::Union{String,Nothing}=nothing`: Write response body to file. Ignored if nothing (default)
- `callback::Union{Function,Nothing}=nothing`: A callback function to handle the response object
"""
function opal_post(
    opal::OpalObject,
    args...;
    query::Dict{String,Any}=Dict{String,Any}(),
    body::String="",
    contentType::String="application/x-rscript",
    acceptType::String="application/json",
    outFile::Union{String,Nothing}=nothing,
    callback::Union{Function,Nothing}=nothing,
    retries::Int=3,
)
    url = _url(opal, args...)
    headers = Dict("Content-Type" => contentType, "Accept" => acceptType)

    # Add authorization headers
    if !isnothing(opal.authorization)
        headers["Authorization"] = opal.authorization
    end
    if !isnothing(opal.token)
        headers["X-Opal-Auth"] = opal.token
    end

    r = if isnothing(outFile)
        HTTP.request(
            "POST",
            url;
            query=query,
            body=body,
            headers=headers,
            status_exception=false,
            retry=true,
            retries=retries,
        )
    else
        # Write to file
        open(outFile, "w") do io
            HTTP.request(
                "POST",
                url;
                query=query,
                body=body,
                headers=headers,
                response_stream=io,
                status_exception=false,
                retry=true,
                retries=retries,
            )
        end
    end

    return _handleResponseOrCallback!(opal, r, callback)
end
