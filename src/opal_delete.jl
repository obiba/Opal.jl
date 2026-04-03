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
    retries::Int=3,
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

    r = request(
        "DELETE",
        url;
        query=query,
        headers=headers,
        status_exception=false,
        retry=true,
        retries=retries,
    )

    return _handleResponseOrCallback!(opal, r, callback)
end
