"""
    opal_resources(opal, project; df=true)

Get the resource references of a project.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::AbstractString`: Name of the project
- `df::Bool=true`: Return a DataFrame (not implemented, returns raw response)
"""
function opal_resources(opal::OpalObject, project::AbstractString; df::Bool=true)
    if !ismissing(opal.version) && opal.version < v"3.0"
        throw(
            ErrorException(
                "Resources are not available in opal $(opal.version) (3.0.0 or higher is required)",
            ),
        )
    end
    res = opal_get(opal, "project", project, "resources")

    if !df
        return res
    end

    if isempty(res)
        return DataFrame(; name=String[], url=String[], format=String[])
    end

    df = DataFrame(res)
    transform!(
        df,
        :resource => ByRow(x -> haskey(x, "url") ? x["url"] : missing) => :url,
        :resource => ByRow(x -> haskey(x, "format") ? x["format"] : missing) => :format,
    )

    return select!(df, Not(:resource, :parameters, :editable, :factory))
end

"""
    opal_resource(opal, project, resource)

Get a resource reference of a project.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::AbstractString`: Name of the project
- `resource::AbstractString`: Name of the resource in the project
"""
function opal_resource(opal::OpalObject, project::AbstractString, resource::AbstractString)
    return opal_get(opal, "project", project, "resource", resource)
end

"""
    opal_resource_exists(opal, project, resource)

Check whether a resource reference exists in a project (and is visible by the requesting user).

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::AbstractString`: Name of the project
- `resource::AbstractString`: Name of the resource in the project
"""
function opal_resource_exists(
    opal::OpalObject, project::AbstractString, resource::AbstractString
)
    res = try
        opal_resource(opal, project, resource)
    catch
        nothing
    end
    return !isnothing(res)
end

"""
    opal_resource_get(opal, project, resource)

Get the resource object of a project. This function requires server-side R session support and resource assignment functionality.

Note: This is a placeholder implementation. The original R implementation uses server-side R execution to assign and retrieve the resource object, which requires additional functionality not yet implemented.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::AbstractString`: Name of the project
- `resource::AbstractString`: Name of the resource in the project
"""
function opal_resource_get(
    opal::OpalObject, project::AbstractString, resource::AbstractString
)
    return throw(
        ErrorException(
            "opal_resource_get is not yet fully implemented. This function requires server-side R session management (opal.assign.resource, opal.execute, opal.symbol_rm) which is not yet available.",
        ),
    )
    # TODO: Implementation requires:
    # 1. opal.assign.resource functionality
    # 2. opal.execute functionality
    # 3. opal.symbol_rm functionality
    # This will be implemented in a future phase when R session operations are added.
end

"""
    opal_resource_create(opal, project, name, url; description=nothing, format=nothing, package=nothing, identity=nothing, secret=nothing)

Create a resource reference in a project.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::AbstractString`: Name of the project
- `name::AbstractString`: Name of the resource in the project
- `url::AbstractString`: The URL of the resource
- `description::Union{AbstractString,Nothing}=nothing`: The description of the resource
- `format::Union{AbstractString,Nothing}=nothing`: The format of the data described by the resource
- `package::Union{AbstractString,Nothing}=nothing`: The R package to be loaded prior to the assignment of the resource
- `identity::Union{AbstractString,Nothing}=nothing`: The identity key or username to be used when accessing the resource
- `secret::Union{AbstractString,Nothing}=nothing`: The secret key or password to be used when accessing the resource
"""
function opal_resource_create(
    opal::OpalObject,
    project::AbstractString,
    name::AbstractString,
    url::AbstractString;
    description::Union{AbstractString,Nothing}=nothing,
    format::Union{AbstractString,Nothing}=nothing,
    package::Union{AbstractString,Nothing}=nothing,
    identity::Union{AbstractString,Nothing}=nothing,
    secret::Union{AbstractString,Nothing}=nothing,
)
    parameters = Dict{String,Any}("url" => url)
    if !isnothing(format)
        parameters["format"] = format
    end
    if !isnothing(package)
        parameters["_package"] = package
    end

    credentials = nothing
    if !isnothing(identity) || !isnothing(secret)
        credentials = Dict{String,Any}()
        if !isnothing(identity)
            credentials["identifier"] = identity
            credentials["identity"] = identity
        end
        if !isnothing(secret)
            credentials["secret"] = secret
        end
    end

    return opal_resource_extension_create(
        opal,
        project,
        name,
        "resourcer",
        "default",
        parameters;
        description=description,
        credentials=credentials,
    )
end

"""
    opal_resource_extension_create(opal, project, name, provider, factory, parameters; description=nothing, credentials=nothing)

Create an extended resource reference in a project.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::AbstractString`: Name of the project
- `name::AbstractString`: Name of the resource in the project
- `provider::AbstractString`: Name of the R package in which the resource is defined
- `factory::AbstractString`: Name of the JS function that turns parameters and credentials into a resource object
- `parameters::Dict{AbstractString,Any}`: A dictionary of the resource parameters
- `description::Union{AbstractString,Nothing}=nothing`: The description of the resource
- `credentials::Union{Dict{AbstractString,Any},Nothing}=nothing`: A dictionary of the resource credentials
"""
function opal_resource_extension_create(
    opal::OpalObject,
    project::AbstractString,
    name::AbstractString,
    provider::AbstractString,
    factory::AbstractString,
    parameters::Dict{<:AbstractString,Any};
    description::Union{AbstractString,Nothing}=nothing,
    credentials::Union{Dict{<:AbstractString,Any},Nothing}=nothing,
)
    if !opal_resource_exists(opal, project, name)
        resjson = Dict{String,Any}(
            "provider" => provider,
            "factory" => factory,
            "project" => project,
            "name" => name,
        )

        if !isnothing(description)
            resjson["description"] = description
        end

        resjson["parameters"] = JSON.json(parameters)

        if !isnothing(credentials)
            resjson["credentials"] = JSON.json(credentials)
        end

        body = JSON.json(resjson)
        opal_post(
            opal, "project", project, "resources"; contentType="application/json", body=body
        )
    else
        @warn "Resource $name in project $project already exists."
    end
end

"""
    opal_resource_delete(opal, project, resource; silent=true)

Delete a resource reference. Removes the reference to a resource. The targeted resource remains untouched.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::AbstractString`: Project name where the resource is located
- `resource::AbstractString`: Resource name to be deleted
- `silent::Bool=true`: Warn if resource does not exist
"""
function opal_resource_delete(
    opal::OpalObject, project::AbstractString, resource::AbstractString; silent::Bool=true
)
    if opal_resource_exists(opal, project, resource)
        opal_delete(opal, "project", project, "resource", resource)
    elseif !silent
        @warn "Resource '$resource' does not exist in project '$project'"
    end
end
