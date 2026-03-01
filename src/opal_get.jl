# TODO: investigate if we can use the terminate_on functionality in Julia.
# This would rely on passing a function to the retry_check kwarg
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
            HTTP.request(
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

    _handleResponseOrCallback(opal, r, callback)
end
