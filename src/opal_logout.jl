"""
    opal_logout(opal; save=false)

Clear the R sessions and logout from Opal.

# Arguments
- `opal::Union{OpalObject, Vector{OpalObject}}`: Opal object or a list of opals
- `save::Union{Bool, String}=false`: Save the workspace with given identifier (default value is false, current session ID if true)
"""
function opal_logout(opal::OpalObject; save::Union{Bool,String}=false)
    res = nothing

    if (isa(save, Bool) && save) || isa(save, String)
        if !ismissing(opal.version) && !isnothing(opal.version)
            # Version compare would go here - simplified for now
            # In R: if opal.version_compare(opal,"2.6")<0
        end
    end

    res = try
        _rmRSession(opal; save=save)
    catch e
        nothing
    end
    opal.rid = nothing

    res = try
        _rmOpalSession(opal)
    catch e
        nothing
    end
    opal.sid = nothing

    return res
end

function opal_logout(opals::Vector{OpalObject}; save::Union{Bool,String}=false)
    return [opal_logout(o; save=save) for o in opals]
end
