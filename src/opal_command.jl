"""
    opal_commands(opal; df=true)

List the asynchronous commands. Get the list of asynchronous R commands in the remote R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `df::Bool=true`: Return a data frame
"""
function opal_commands(opal::OpalObject; df::Bool=true)
    if _versionCompare(opal, "2.1") < 0
        return nothing
    end
    res = opal_get(opal, opal.context, "session", opal_session(opal), "commands")
    if !df
        return res
    end
    if isnothing(res) || isempty(res)
        return DataFrame()
    end
    id = String[]
    script = Union{Missing,String}[]
    status = Union{Missing,String}[]
    withResult = Union{Missing,Bool}[]
    createDate = Union{Missing,String}[]
    startDate = Union{Missing,String}[]
    endDate = Union{Missing,String}[]
    for item in res
        push!(id, get(item, "id", ""))
        push!(script, get(item, "script", missing))
        push!(status, get(item, "status", missing))
        push!(withResult, get(item, "withResult", missing))
        push!(createDate, get(item, "createDate", missing))
        push!(startDate, get(item, "startDate", missing))
        push!(endDate, get(item, "endDate", missing))
    end
    return DataFrame(;
        id=id,
        script=script,
        status=status,
        withResult=withResult,
        createDate=createDate,
        startDate=startDate,
        endDate=endDate,
    )
end

"""
    opal_command(opal, id; wait=false)

Get an asynchronous R command in the remote R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `id::Union{Nothing, String}`: R command ID
- `wait::Bool=false`: Wait for the command to complete
"""
function opal_command(opal::OpalObject, id::Union{Nothing,String}; wait::Bool=false)
    if isnothing(id) || _versionCompare(opal, "2.1") < 0
        return nothing
    end
    query = Dict{String,Any}()
    if wait
        query["wait"] = "true"
    end
    return opal_get(
        opal, opal.context, "session", opal_session(opal), "command", id; query=query
    )
end

"""
    opal_command_rm(opal, id)

Remove an asynchronous R command in the remote R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `id::Union{Nothing, String}`: R command ID
"""
function opal_command_rm(opal::OpalObject, id::Union{Nothing,String})
    if isnothing(id) || _versionCompare(opal, "2.1") < 0
        return nothing
    end
    try
        opal_delete(opal, opal.context, "session", opal_session(opal), "command", id)
    catch
        # Ignore errors
    end
    return nothing
end

"""
    opal_commands_rm(opal)

Remove all asynchronous R commands in the remote R session.

# Arguments
- `opal::OpalObject`: Opal connection object
"""
function opal_commands_rm(opal::OpalObject)
    if _versionCompare(opal, "2.1") < 0
        return nothing
    end
    commands = opal_commands(opal; df=false)
    if !isnothing(commands)
        for cmd in commands
            opal_command_rm(opal, get(cmd, "id", nothing))
        end
    end
    return nothing
end

"""
    opal_command_result(opal, id; wait=false)

Get the result of an asynchronous R command in the remote R session. The command is
removed from the remote R session after this call.

# Arguments
- `opal::OpalObject`: Opal connection object
- `id::Union{Nothing, String}`: R command ID
- `wait::Bool=false`: Wait for the command to complete
"""
function opal_command_result(opal::OpalObject, id::Union{Nothing,String}; wait::Bool=false)
    if isnothing(id) || _versionCompare(opal, "2.1") < 0
        return id
    end
    if wait
        cmd = opal_command(opal, id; wait=true)
        if get(cmd, "status", "") == "FAILED"
            msg = get(cmd, "error", "<no message>")
            throw(
                ErrorException(
                    "Command '$(get(cmd, "script", ""))' failed on '$(opal.name)': $(msg)"
                ),
            )
        end
    end
    return opal_get(
        opal,
        opal.context,
        "session",
        opal_session(opal),
        "command",
        id,
        "result";
        acceptType="application/octet-stream",
    )
end
