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
    callback::Union{Function,Nothing}=nothing,
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

    # Retry logic - simplified version
    retry_times = 3
    last_error = nothing

    for attempt in 1:retry_times
        try
            r = HTTP.request(
                "PUT", url; query=query, body=body, headers=headers, status_exception=false
            )

            # Check if we should retry based on status
            if r.status >= 400 && r.status < 600 && attempt < retry_times
                last_error = r
                continue
            end

            return _handleResponseOrCallback!(opal, r, callback)
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
            return _handleResponseOrCallback!(opal, last_error, callback)
        else
            rethrow(last_error)
        end
    end
end
