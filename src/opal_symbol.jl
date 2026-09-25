"""
    opal_symbols(opal)

List R symbols. Get the R symbols available in the remote R session.

# Arguments
- `opal::OpalObject`: Opal connection object
"""
function opal_symbols(opal::OpalObject)
    return opal_get(
        opal,
        opal.context,
        "session",
        opal_session(opal),
        "symbols";
        acceptType="application/json",
    )
end

"""
    opal_symbol_rm(opal, symbol)

Remove a R symbol from the remote R session.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
"""
function opal_symbol_rm(opal::OpalObject, symbol::String)
    try
        opal_delete(opal, opal.context, "session", opal_session(opal), "symbol", symbol)
    catch
        # Ignore errors
    end
    return nothing
end

"""
    opal_rm(opal, symbol)

Remove a symbol from the current R session. Deprecated: see opal_symbol_rm function instead.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol
"""
function opal_rm(opal::OpalObject, symbol::String)
    return opal_symbol_rm(opal, symbol)
end

"""
    opal_symbol_save(opal, symbol, destination)

Save a tibble identified by symbol as a file of format SAS, SPSS, Stata, CSV or TSV
in the remote R session working directory.

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol representing a tibble
- `destination::Union{String, Nothing}`: The path of the file in the R session workspace. Supported file extensions are:
  .sav (SPSS), .zsav (compressed SPSS), .sas7bdat (SAS), .xpt (SAS Transport), .dta (Stata),
  .csv (comma separated values), .tsv (tab separated values)
"""
function opal_symbol_save(
    opal::OpalObject, symbol::String, destination::Union{Nothing,String}
)
    if !ismissing(opal.version) && _versionCompare(opal, "2.8") < 0
        throw(
            ErrorException(
                "Saving tibble in a file is not available for opal $(opal.version) (2.8.0 or higher is required)",
            ),
        )
    else
        if isnothing(destination)
            throw(ErrorException("Destination file path is missing or empty."))
        end
        if endswith(destination, ".zsav") || endswith(destination, ".xpt")
            if !ismissing(opal.version) && _versionCompare(opal, "2.14") < 0
                throw(
                    ErrorException(
                        "Saving tibble in a compressed SPSS or SAS Transport file is not available for opal $(opal.version) (2.14.0 or higher is required)",
                    ),
                )
            end
        end
        query = Dict{String,Any}("destination" => destination)
        opal_put(
            opal,
            opal.context,
            "session",
            opal_session(opal),
            "symbol",
            symbol,
            "_save";
            query=query,
        )
    end
    return nothing
end

"""
    opal_symbol_import(opal, symbol, project; identifiers=nothing, policy="required", id_name="id", type="Participant", wait=true)

Import a tibble identified by the symbol as a table in Opal. This operation creates
an importation task in Opal that can be followed (see tasks related functions).

# Arguments
- `opal::OpalObject`: Opal connection object
- `symbol::String`: Name of the R symbol representing a tibble
- `project::String`: Name of the project into which the data are to be imported
- `identifiers::Union{String, Nothing}=nothing`: Name of the identifiers mapping to use when assigning entities to Opal
- `policy::String="required"`: Identifiers policy: 'required' (each identifiers must be mapped prior importation (default)), 'ignore' (ignore unknown identifiers) and 'generate' (generate a system identifier for each unknown identifier)
- `id_name::String="id"`: The name of the column representing the entity identifiers
- `type::String="Participant"`: Entity type (what the data are about)
- `wait::Bool=true`: Wait for import task completion
"""
function opal_symbol_import(
    opal::OpalObject,
    symbol::String,
    project::String;
    identifiers::Union{Nothing,String}=nothing,
    policy::String="required",
    id_name::String="id",
    type::String="Participant",
    wait::Bool=true,
)
    rid = opal_session(opal)
    if !ismissing(opal.version) && _versionCompare(opal, "2.8") < 0
        @warn "Importing tibble in a table not available for opal $(opal.version) (2.8.0 or higher is required)"
        return nothing
    else
        dsFactory = Dict{String,Any}(
            "session" => rid,
            "symbol" => symbol,
            "entityType" => type,
            "idColumn" => id_name,
        )
        if isnothing(identifiers)
            dsFactoryJson =
                "{\"Magma.RSessionDatasourceFactoryDto.params\": " *
                _listToJson(dsFactory) *
                "}"
        else
            idConfig = Dict{String,Any}("name" => identifiers)
            if policy == "required"
                idConfig["allowIdentifierGeneration"] = true
                idConfig["ignoreUnknownIdentifier"] = true
            elseif policy == "ignore"
                idConfig["allowIdentifierGeneration"] = false
                idConfig["ignoreUnknownIdentifier"] = true
            else
                idConfig["allowIdentifierGeneration"] = false
                idConfig["ignoreUnknownIdentifier"] = false
            end
            dsFactoryJson =
                "{\"Magma.RSessionDatasourceFactoryDto.params\": " *
                _listToJson(dsFactory) *
                ", \"idConfig\":" *
                _listToJson(idConfig) *
                "}"
        end
        created = opal_post(
            opal,
            "project",
            project,
            "transient-datasources";
            body=dsFactoryJson,
            contentType="application/json",
        )
        importCmd = Dict{String,Any}(
            "destination" => project, "tables" => ["$(created["name"]).$(symbol)"]
        )
        location = opal_post(
            opal,
            "project",
            project,
            "commands",
            "_import";
            body=_listToJson(importCmd),
            contentType="application/json",
            callback=(_handleResponseLocation!),
        )
        if !isnothing(location)
            # /shell/command/<id>
            task = location[16:end]
            if wait
                status = "NA"
                waited = 0.0
                while status ∉ ("SUCCEEDED", "FAILED", "CANCELED")
                    # delay is proportional to the time waited, but no more than 10s
                    delay = min(10, max(1, round(waited / 10)))
                    sleep(delay)
                    waited += delay
                    command = opal_get(opal, "shell", "command", task)
                    status = command["status"]
                end
                if status ∈ ("FAILED", "CANCELED")
                    throw(
                        ErrorException(
                            "Import of \"$(symbol)\" ended with status: $(status)"
                        ),
                    )
                end
            else
                # returns the task ID so that task completion can be followed
                return task
            end
        else
            # not supposed to be here
            return location
        end
    end
end
