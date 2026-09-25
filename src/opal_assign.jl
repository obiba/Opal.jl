using Serialization: serialize

"""
    opal_assign(opal, symbol, value; variables=nothing, missings=false, identifiers=nothing, id_name=nothing, updated_name=nothing, async=false)

Assign a Opal table, or a R expression to a R symbol in the current R session.
The value assignment is evaluated in the following order: a R expression (Julia Expr),
a fully qualified name of a variable or a table in Opal or any other assignment type.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
- `value`: The value to assign: a R expression (Expr) to assign as script, or a fully qualified name of a table (String), or any other value (pushed as data)
- `variables::Union{Nothing, String, Vector{String}}=nothing`: List of variable names or Javascript expression that selects the variables of a table (ignored if value does not refer to a table)
- `missings::Bool=false`: If true, missing values will be pushed from Opal to R. Ignored if value is an R expression
- `identifiers::Union{Nothing, String}=nothing`: Name of the identifiers mapping to use when assigning entities to R
- `id_name::Union{Nothing, String}=nothing`: Add a vector with the given name representing the entity identifiers
- `updated_name::Union{Nothing, String}=nothing`: Add a vector with the given name representing the creation and last update timestamps
- `async::Bool=false`: R script is executed asynchronously within the session. If true, the value returned is the ID of the command to look for
"""
function opal_assign(
    opal::OpalObject,
    symbol::String,
    value;
    variables=nothing,
    missings=false,
    identifiers=nothing,
    id_name=nothing,
    updated_name=nothing,
    async=false,
)
    if value isa Expr
        opal_assign_script(opal, symbol, value; async=async)
    elseif value isa String
        pal = value
        opal_assign_table(
            opal,
            symbol,
            pal;
            variables=variables,
            missings=missings,
            identifiers=identifiers,
            id_name=id_name,
            updated_name=updated_name,
            async=async,
        )
    else
        opal_assign_data(opal, symbol, value; async=async)
    end
    return nothing
end

"""
    opal_assign_table(opal, symbol, value; variables=nothing, missings=false, identifiers=nothing, id_name=nothing, updated_name=nothing, class="data.frame", async=false)

Assign a Opal table to a data frame identified by a R symbol in the current R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
- `value::String`: The fully qualified name of a variable or a table in Opal
- `variables::Union{Nothing, String, Vector{String}}=nothing`: List of variable names or Javascript expression that selects the variables of a table
- `missings::Bool=false`: If true, missing values will be pushed from Opal to R
- `identifiers::Union{Nothing, String}=nothing`: Name of the identifiers mapping to use when assigning entities to R
- `id_name::Union{Nothing, String}=nothing`: Add a vector with the given name representing the entity identifiers
- `updated_name::Union{Nothing, String}=nothing`: Add a vector with the given name representing the creation and last update timestamps
- `class::String="data.frame"`: The data frame class into which the table is written: can 'data.frame' (default) or 'tibble' (from Opal 2.6 to 2.13) or 'tibble.with.factors' (from Opal 2.14)
- `async::Bool=false`: R script is executed asynchronously within the session. If true, the value returned is the ID of the command to look for
"""
function opal_assign_table(
    opal::OpalObject,
    symbol::String,
    value::String;
    variables=nothing,
    missings=false,
    identifiers=nothing,
    id_name=nothing,
    updated_name=nothing,
    class="data.frame",
    async=false,
)
    contentType = "application/x-opal"
    body = value
    variableFilter = nothing
    if variables isa String
        # case variables is a magma script
        variableFilter = variables
    elseif variables isa Vector{String}
        # case variables is a list of variable names
        variableFilter = "name().any('" * join(variables, "','") * "')"
    end

    query = Dict{String,Any}("missings" => missings)
    if !isnothing(variableFilter)
        query["variables"] = variableFilter
    end
    if !isnothing(identifiers)
        query["identifiers"] = identifiers
    end
    if !isnothing(id_name)
        query["id"] = id_name
    end
    if !isnothing(updated_name)
        query["updated"] = updated_name
    end
    if !isnothing(class)
        query["class"] = class
    end
    if async
        query["async"] = "true"
    end

    res = opal_put(
        opal,
        opal.context,
        "session",
        opal_session(opal),
        "symbol",
        symbol;
        body=body,
        contentType=contentType,
        query=query,
    )
    if async
        return res
    end
    return nothing
end

"""
    opal_assign_table_tibble(opal, symbol, value; variables=nothing, missings=false, identifiers=nothing, id_name="id", with_factors=false, updated_name=nothing, async=false)

Assign a Opal table to a tibble identified by a R symbol in the current R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
- `value::String`: The fully qualified name of a table in Opal
- `variables::Union{Nothing, String, Vector{String}}=nothing`: List of variable names or Javascript expression that selects the variables of a table
- `missings::Bool=false`: If true, missing values will be pushed from Opal to R
- `identifiers::Union{Nothing, String}=nothing`: Name of the identifiers mapping to use when assigning entities to R
- `id_name::String="id"`: Add a vector with the given name representing the entity identifiers
- `with_factors::Bool=false`: If true, the categorical variables will be assigned as factors (from Opal 2.14)
- `updated_name::Union{Nothing, String}=nothing`: Add a vector with the given name representing the creation and last update timestamps
- `async::Bool=false`: R script is executed asynchronously within the session. If true, the value returned is the ID of the command to look for
"""
function opal_assign_table_tibble(
    opal::OpalObject,
    symbol::String,
    value::String;
    variables=nothing,
    missings=false,
    identifiers=nothing,
    id_name="id",
    with_factors=false,
    updated_name=nothing,
    async=false,
)
    opal_session(opal)
    if !ismissing(opal.version) && _versionCompare(opal, "2.8") < 0
        @warn "Export to tibble not available for opal $(opal.version) (2.8.0 or higher is required)"
    elseif with_factors && !ismissing(opal.version) && _versionCompare(opal, "2.14") < 0
        @warn "Export to tibble with factors not available for opal $(opal.version) (2.14.0 or higher is required)"
    else
        cls = "tibble"
        if with_factors
            cls = "tibble.with.factors"
        end
        return opal_assign_table(
            opal,
            symbol,
            value;
            variables=variables,
            missings=missings,
            identifiers=identifiers,
            id_name=id_name,
            updated_name=updated_name,
            class=cls,
            async=async,
        )
    end
    return nothing
end

"""
    opal_assign_script(opal, symbol, value; async=false)

Assign a R script or expression to a R symbol in the current R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
- `value`: The R expression to assign as string, or as Julia expression
- `async::Bool=false`: R script is executed asynchronously within the session. If true, the value returned is the ID of the command to look for
"""
function opal_assign_script(
    opal::OpalObject, symbol::String, value::Union{String,Expr}; async::Bool=false
)
    contentType = "application/x-rscript"
    body = _deparse(value)
    query = Dict{String,Any}()
    if async
        query["async"] = "true"
    end
    res = opal_put(
        opal,
        opal.context,
        "session",
        opal_session(opal),
        "symbol",
        symbol;
        body=body,
        contentType=contentType,
        query=query,
    )
    if async
        return res
    end
    return nothing
end

"""
    opal_assign_data(opal, symbol, value; async=false)

Assign a R object to a R symbol in the current R session, serialized in base64.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
- `value`: The value to assign (vector, data frame)
- `async::Bool=false`: R script is executed asynchronously within the session. If true, the value returned is the ID of the command to look for
"""
function opal_assign_data(opal::OpalObject, symbol::String, value; async::Bool=false)
    contentType = "application/x-rdata"
    io = IOBuffer()
    serialize(io, value)
    body = base64encode(take!(io))
    query = Dict{String,Any}()
    if async
        query["async"] = "true"
    end
    res = opal_post(
        opal,
        opal.context,
        "session",
        opal_session(opal),
        "symbol",
        symbol;
        body=body,
        contentType=contentType,
        query=query,
    )
    if async
        return res
    end
    return nothing
end

"""
    opal_assign_resource(opal, symbol, value; async=false)

Assign a Opal resource to a R symbol in the current R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
- `value::String`: The fully qualified name of a resource in Opal
- `async::Bool=false`: R script is executed asynchronously within the session. If true, the value returned is the ID of the command to look for
"""
function opal_assign_resource(
    opal::OpalObject, symbol::String, value::String; async::Bool=false
)
    if !ismissing(opal.version) && _versionCompare(opal, "3.0") < 0
        throw(
            ErrorException(
                "Resources are not available in opal $(opal.version) (3.0.0 or higher is required)",
            ),
        )
    end
    query = Dict{String,Any}()
    if async
        query["async"] = "true"
    end
    res = opal_put(
        opal,
        opal.context,
        "session",
        opal_session(opal),
        "symbol",
        symbol,
        "resource",
        value;
        query=query,
    )
    if async
        return res
    end
    return nothing
end
