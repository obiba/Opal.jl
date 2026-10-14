"""
    opal_session(opal; wait=true) -> String

Create the R session if it does not exist and returns its identifier.

# Arguments
- `opal::OpalObject`: Opal object
- `wait::Bool=true`: Wait for R session to be operational
"""
function opal_session(opal::OpalObject; wait::Bool=true)
    if isnothing(opal.rid)
        opal.rid = _newSession(opal; restore=opal.restore, profile=opal.profile, wait=wait)
    end
    if isnothing(opal.rid)
        throw(ErrorException("Remote R session not available"))
    end
    return opal.rid
end

"""
    opal_session_get(opal)

Get the R session details if it exists.

# Arguments
- `opal::OpalObject`: Opal object
"""
function opal_session_get(opal::OpalObject)
    if isnothing(opal.rid)
        throw(ErrorException("Remote R session not available"))
    end
    return opal_get(opal, opal.context, "session", opal.rid)
end

"""
    opal_session_exists(opal) -> Bool

Check if the remote R session exists.

# Arguments
- `opal::OpalObject`: Opal object
"""
function opal_session_exists(opal::OpalObject)
    if isnothing(opal.rid)
        return false
    end
    try
        opal_get(opal, opal.context, "session", opal.rid)
        return true
    catch e
        return false
    end
end

"""
    opal_session_running(opal) -> Bool

Check if the remote R session is running and ready to receive R commands.
Fails if the session does not exist.

# Arguments
- `opal::OpalObject`: Opal object
"""
function opal_session_running(opal::OpalObject)
    if isnothing(opal.rid)
        throw(ErrorException("Remote R session not available"))
    end
    res = opal_get(opal, opal.context, "session", opal.rid)

    if isa(res, Dict)
        if haskey(res, "state")
            return lowercase(res["state"]) == "running"
        else
            # Older opal servers do not have state for the R session
            return true
        end
    end

    return false
end

"""
    opal_session_delete(opal)

Delete the remote R session. Ignored if the session does not exist.

# Arguments
- `opal::OpalObject`: Opal object
"""
function opal_session_delete(opal::OpalObject)
    if !isnothing(opal.rid)
        try
            opal_delete(opal, opal.context, "session", opal.rid)
        catch e
            # Ignore errors
        end
        opal.rid = nothing
    end
    return nothing
end
