"""
    opal_delete(opal, args...; query=Dict(), callback=nothing)

Generic REST resource deletion.

# Arguments
- `opal::OpalObject`: Opal object
- `args...`: Resource path segments
- `query::Dict{String,Any}=Dict()`: Named dictionary of query parameters
- `callback::Union{Function,Nothing}=nothing`: A callback function to handle the response object
"""
function opal_delete(
    opal::OpalObject,
    args...;
    query::Dict{String,Any}=Dict(),
    callback::Union{Function,Nothing}=nothing,
)
    url = _url(opal, args...)
    headers = Dict{String,String}()

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
                "DELETE", url; query=query, headers=headers, status_exception=false
            )

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
