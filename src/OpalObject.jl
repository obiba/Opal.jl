
mutable struct OpalObject
    username::String
    url::String
    name::String
    version::Union{String,Missing}
    encoding::String
    uprofile::Dict{String,Any}
    authorization::Union{String,Nothing}
    token::Union{String,Nothing}
    config::Dict{Symbol,Any}
    rid::Union{Int,Nothing}
    restore::Union{Bool,Nothing}
    profile::Union{String,Nothing}
    context::String
end

function OpalObject(; kwargs...)
    return OpalObject(
        get(kwargs, :username, ""),
        get(kwargs, :url, ""),
        get(kwargs, :name, ""),
        get(kwargs, :version, missing),
        get(kwargs, :encoding, "UTF-8"),
        get(kwargs, :uprofile, Dict{String,Any}()),
        get(kwargs, :authorization, nothing),
        get(kwargs, :token, nothing),
        get(kwargs, :config, Dict{Symbol,Any}()),
        get(kwargs, :rid, nothing),
        get(kwargs, :restore, nothing),
        get(kwargs, :profile, nothing),
        get(kwargs, :context, "r"),
    )
end
