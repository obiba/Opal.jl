"""
    opal_logout(opal; save=false)

Clear the R sessions and logout from Opal.

# Arguments
- `opal::Union{OpalObject, Vector{OpalObject}}`: Opal object or a list of opals
- `save::Union{Bool, String}=false`: Save the workspace with given identifier (default value is false, current session ID if true)
"""
function opal_logout(opal::OpalObject; save::Union{Bool,String}=false)
    # Workspaces are not available for opal < 2.6
    if ((isa(save, Bool) && save) || isa(save, String)) &&
        !ismissing(opal.version) &&
        !isnothing(opal.version) &&
        _versionCompare(opal, "2.6") < 0
        @warn "Workspaces are not available for opal $(opal.version) (2.6.0 or higher is required)"
    end

    # When save=true, _rmRSession returns the workspace id (the current
    # session id); keep it instead of overwriting it with the result of
    # _rmOpalSession (which returns nothing).
    res = try
        _rmRSession(opal; save=save)
    catch
        nothing
    end
    opal.rid = nothing

    opalRes = try
        _rmOpalSession(opal)
    catch
        nothing
    end
    opal.sid = nothing
    opal.csrf = nothing

    if isa(res, String)
        return res
    end
    return opalRes
end

function opal_logout(opals::Vector{OpalObject}; save::Union{Bool,String}=false)
    return [opal_logout(o; save=save) for o in opals]
end
