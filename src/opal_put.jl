"""
    opal_put(opal, args...; query=Dict(), body="", contentType="application/x-rscript", callback=nothing)

Generic REST resource update.

# Arguments
- `opal::OpalObject`: Opal object
- `args...`: Resource path segments
- `query::Dict{String,Any}=Dict()`: Named dictionary of query parameters
- `body::String=""`: The body of the request
- `contentType::String="application/x-rscript"`: The type of the body content
- `callback::Union{Function,Nothing}=nothing`: A callback function to handle the response object
"""
function opal_put(
    opal::OpalObject,
    args...;
    query::Dict{String,Any}=Dict(),
    body::String="",
    contentType::String="application/x-rscript",
    outFile::Union{String,Nothing}=nothing,
    callback::Union{Function,Nothing}=nothing,
    retries::Int=3,
)
    url = _url(opal, args...)
    headers = Dict("Content-Type" => contentType)

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

    r = if isnothing(outFile)
        HTTP.request(
            "PUT",
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
                "PUT",
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
