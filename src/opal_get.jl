function opal_get(
    opal::OpalObject,
    args...;
    query::Dict{String,Any}=Dict(),
    acceptType::String="application/json",
    outFile::Union{String,Nothing}=nothing,
    callback::Union{Function,Nothing}=nothing,
)
    r = nothing
    logerrors = false
    times = 3
    url = _url(opal, args...)
    if isnothing(outFile)
        r = request(
            "GET",
            url;
            query=query,
            headers=Dict("Accept" => acceptType),
            logerrors=logerrors,
            times=times,
        )
    else
        r = request(
            "GET",
            url;
            query=query,
            headers=Dict("Accept" => acceptType),
            logerrors=logerrors,
            times=times,
            # write_disk(outFile, overwrite = true),
            # config = opal.config,
        )
    end

    _handleResponseOrCallback(opal, r, callback)
end
