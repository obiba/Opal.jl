"""
    opal_post(opal, args...; query=Dict(), body="", contentType="application/x-rscript", acceptType="application/json", outFile=nothing, callback=nothing)

Generic REST resource creation.

# Arguments
- `opal::OpalObject`: Opal object
- `args...`: Resource path segments
- `query::Dict{String,Any}=Dict()`: Named dictionary of query parameters
- `body::String=""`: The body of the request
- `contentType::String="application/x-rscript"`: The type of the body content
- `acceptType::String="application/json"`: The type of the body content
- `outFile::Union{String,Nothing}=nothing`: Write response body to file. Ignored if nothing (default)
- `callback::Union{Function,Nothing}=nothing`: A callback function to handle the response object
"""
function opal_post(
    opal::OpalObject,
    args...;
    query::Dict{String,Any}=Dict(),
    body::String="",
    contentType::String="application/x-rscript",
    acceptType::String="application/json",
    outFile::Union{String,Nothing}=nothing,
    callback::Union{Function,Nothing}=nothing,
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

    # Retry logic - simplified version (R uses RETRY from httr)
    retry_times = 3
    last_error = nothing

    for attempt in 1:retry_times
        try
            r = if isnothing(outFile)
                HTTP.request(
                    "POST",
                    url;
                    query=query,
                    body=body,
                    headers=headers,
                    status_exception=false,
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
                    )
                end
            end

            # Check if we should retry based on status
            if r.status >= 400 && r.status < 600 && attempt < retry_times
                last_error = r
                continue
            end

            return _handleResponseOrCallback(opal, r, callback)
        catch e
            last_error = e
            if attempt == retry_times
                rethrow(e)
            end
        end
    end

    # If we got here, we exhausted retries
    if !isnothing(last_error)
        if isa(last_error, HTTP.Response)
            return _handleResponseOrCallback(opal, last_error, callback)
        else
            rethrow(last_error)
        end
    end
end
