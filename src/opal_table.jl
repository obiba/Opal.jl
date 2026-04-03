"""
    opal_table(opal, datasource, table; counts=false)

Get a table from a datasource.

# Arguments
- `opal::OpalObject`: Opal connection object
- `datasource::String`: Name of the datasource (project)
- `table::String`: Name of the table in the datasource
- `counts::Bool=false`: Flag to get the number of variables and entities
"""
function opal_table(opal::OpalObject, datasource::String, table::String; counts::Bool=false)
    query = Dict{String,Any}()
    if counts
        query["counts"] = true
    end

    return opal_get(opal, "datasource", datasource, "table", table; query=query)
end

"""
    opal_table_exists(opal, project, table; view=missing)

Check whether a Opal table exists (and is visible). Optionally check whether the table is a raw table or a view.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::String`: Project name where the table is located
- `table::String`: Table name
- `view::Union{Bool,Missing}=missing`: Logical to perform an additional check whether the table is a view (true) or a raw table (false). If missing, the table can be indifferently a view or a raw table
"""
function opal_table_exists(
    opal::OpalObject, project::String, table::String; view::Union{Bool,Missing}=missing
)
    res = try
        opal_table(opal, project, table)
    catch
        nothing
    end

    if !isnothing(res) && !ismissing(view) && isa(view, Bool)
        if view
            haskey(res, "viewLink") && !isnothing(res["viewLink"])
        else
            !haskey(res, "viewLink") || isnothing(res["viewLink"])
        end
    else
        !isnothing(res)
    end
end

"""
    opal_table_delete(opal, project, table; silent=true)

Delete a Opal table. Removes both values and data dictionary of a table, or remove the table's logic if the table is a view. Fails if the table does not exist.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::String`: Project name where the table is located
- `table::String`: Table name to be deleted
- `silent::Bool=true`: Warn if table does not exist
"""
function opal_table_delete(
    opal::OpalObject, project::String, table::String; silent::Bool=true
)
    if opal_table_exists(opal, project, table)
        opal_delete(opal, "datasource", project, "table", table)
    elseif !silent
        @warn "Table '$table' does not exist in project '$project'"
    end
end

"""
    opal_table_create(opal, project, table; type="Participant", tables=nothing)

Create an Opal table or view if it does not already exist. If a list of table references are provided, the table will be a view. The table/view created will have no dictionary.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::String`: Project name where the table will be located
- `table::String`: Table name to be created
- `type::String="Participant"`: Entity type (ignored if table references are provided)
- `tables::Union{Vector{String},Nothing}=nothing`: List of the fully qualified table names that are referred by the view
"""
function opal_table_create(
    opal::OpalObject,
    project::String,
    table::String;
    type::String="Participant",
    tables::Union{Vector{String},Nothing}=nothing,
)
    if !opal_table_exists(opal, project, table)
        if isnothing(tables) || isempty(tables)
            body = JSON.json(Dict("name" => table, "entityType" => type))
            opal_post(
                opal,
                "datasource",
                project,
                "tables";
                contentType="application/json",
                body=body,
            )
        else
            body = JSON.json(
                Dict(
                    "name" => table,
                    "from" => tables,
                    "Magma.VariableListViewDto.view" => Dict("variables" => []),
                ),
            )
            opal_post(
                opal,
                "datasource",
                project,
                "views";
                contentType="application/json",
                body=body,
            )
        end
    else
        throw(ErrorException("Table '$table' already exists in project '$project'."))
    end
end

"""
    opal_table_truncate(opal, project, table)

Truncate a Opal table. Removes the values of a table and keep the dictionary untouched. Fails if the table does not exist or is a view.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::String`: Project name where the table is located
- `table::String`: Table name to be truncated
"""
function opal_table_truncate(opal::OpalObject, project::String, table::String)
    if opal_table_exists(opal, project, table; view=false)
        opal_delete(opal, "datasource", project, "table", table, "valueSets")
    else
        @warn "Table '$table' does not exist in project '$project' or is a view."
    end
end

"""
    opal_table_get(opal, project, table; id_name="id")

Get a Opal table as a DataFrame. Shortcut function to export a Opal table to an RDS file and retrieve it. Requires to have the permission to see the individual values of the table. Requires Opal 4.0+.

Note: This is a simplified implementation that assumes Opal 4.0+ is available. The original R implementation includes fallback logic for older Opal versions, which is not included here.

# Arguments
- `opal::OpalObject`: Opal connection object
- `project::String`: Project name where the table is located
- `table::String`: Table name from which the DataFrame should be extracted
- `id_name::String="id"`: The name of the column representing the entity identifiers
"""
function opal_table_get(
    opal::OpalObject, project::String, table::String; id_name::String="id"
)
    throw(
        ErrorException(
            "opal_table_get is not yet fully implemented. This function requires additional dependencies (DataFrames.jl, file operations) and server-side R session management.",
        ),
    )
    # TODO: Implementation requires:
    # 1. File operations (opal_file_mkdir_tmp, opal_file_download, opal_file_rm)
    # 2. Table export functionality (opal_table_export)
    # 3. RDS file reading capability
    # 4. DataFrames.jl integration
    # This will be implemented in a future phase when file operations are added.
end
