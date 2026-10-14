"""
    opal_workspaces(opal)

Get the R workspaces from a opal.

# Arguments
- `opal::OpalObject`: Opal connection object
"""
function opal_workspaces(opal::OpalObject)
    if !ismissing(opal.version) && _versionCompare(opal, "2.6") < 0
        @warn "Workspaces are not available for opal $(opal.version) (2.6.0 or higher is required)"
    else
        query = Dict{String,Any}("context" => "R")
        wss = opal_get(opal, "service", "r", "workspaces"; query=query)
        if !isnothing(wss) && !isempty(wss)
            name = String[]
            user = String[]
            context = String[]
            lastAccessDate = String[]
            size = Int[]
            for ws in wss
                push!(name, get(ws, "name", ""))
                push!(user, get(ws, "user", ""))
                push!(context, get(ws, "context", ""))
                push!(lastAccessDate, get(ws, "lastAccessDate", ""))
                push!(size, get(ws, "size", 0))
            end
            return DataFrame(;
                name=name,
                user=user,
                context=context,
                lastAccessDate=lastAccessDate,
                size=size,
            )
        end
    end
    return nothing
end

"""
    opal_workspace_rm(opal, ws; user=nothing)

Remove a R workspace from a opal.

# Arguments
- `opal::OpalObject`: Opal connection object
- `ws::String`: The workspace name
- `user::Union{String, Nothing}=nothing`: The user name associated to the workspace. If not provided, the current user is applied
"""
function opal_workspace_rm(
    opal::OpalObject, ws::String; user::Union{Nothing,String}=nothing
)
    if !ismissing(opal.version) && _versionCompare(opal, "2.6") < 0
        @warn "Workspaces are not available for opal $(opal.version) (2.6.0 or higher is required)"
    else
        u = user
        if isnothing(user)
            u = opal.username
        end
        if isnothing(u) || isempty(u)
            throw(ErrorException("User name is missing or empty."))
        end
        if isempty(ws)
            throw(ErrorException("Workspace name is missing or empty."))
        end
        query = Dict{String,Any}("context" => "R", "name" => ws, "user" => u)
        opal_delete(opal, "service", "r", "workspaces"; query=query)
    end
    return nothing
end

"""
    opal_workspace_save(opal, save=true) -> Union{Bool, String}

Save the current session in a opal R workspace.

# Arguments
- `opal::OpalObject`: Opal connection object
- `save::Union{Bool, String}=true`: Save the workspace with given identifier (default is true, current session ID if true)
"""
function opal_workspace_save(opal::OpalObject, save::Union{Bool,String}=true)
    if !ismissing(opal.version) && _versionCompare(opal, "2.6") < 0
        @warn "Workspaces are not available for opal $(opal.version) (2.6.0 or higher is required)"
    else
        saveId = save
        if isa(save, Bool) && save
            saveId = opal.rid
        end
        query = Dict{String,Any}()
        if !isnothing(saveId)
            query["save"] = saveId
        end
        opal_post(
            opal, opal.context, "session", opal_session(opal), "workspaces"; query=query
        )
        return saveId
    end
end

"""
    opal_workspace_restore(opal, ws)

Restore a R workspace from a opal.

# Arguments
- `opal::OpalObject`: Opal connection object
- `ws::String`: The workspace name
"""
function opal_workspace_restore(opal::OpalObject, ws::String)
    if !ismissing(opal.version) && _versionCompare(opal, "4.5") < 0
        @warn "Workspace restore is not available for opal $(opal.version) (4.5.0 or higher is required)"
    else
        if isempty(ws)
            throw(ErrorException("Workspace name is missing or empty."))
        end
        opal_put(opal, opal.context, "session", opal_session(opal), "workspace", ws)
    end
    return nothing
end
