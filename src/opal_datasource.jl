"""
    opal_datasources(opal; df=true)

Get datasources.

# Arguments
- `opal::OpalObject`: Opal connection object
- `df::Bool=true`: Return a data frame
"""
function opal_datasources(opal::OpalObject; df::Bool=true)
    res = opal_get(opal, "datasources")
    if !df
        return res
    end
    name = String[]
    tables = Union{Missing,String}[]
    type = Union{Missing,String}[]
    created = Union{Missing,String}[]
    lastUpdate = Union{Missing,String}[]
    if !isnothing(res)
        for item in res
            push!(name, get(item, "name", ""))
            itype = get(item, "type", nothing)
            if !isnothing(itype) && itype != "null"
                push!(type, itype)
            else
                push!(type, missing)
            end
            itables = get(item, "table", nothing)
            if itables isa String
                push!(tables, itables)
            elseif itables isa AbstractVector
                push!(tables, join(itables, "|"))
            else
                push!(tables, missing)
            end
            timestamps = get(item, "timestamps", nothing)
            if !isnothing(timestamps)
                push!(created, get(timestamps, "created", missing))
                push!(lastUpdate, get(timestamps, "lastUpdate", missing))
            else
                push!(created, missing)
                push!(lastUpdate, missing)
            end
        end
    end
    return DataFrame(;
        name=name, tables=tables, type=type, created=created, lastUpdate=lastUpdate
    )
end

"""
    opal_datasource(opal, datasource)

Get a datasource.

# Arguments
- `opal::OpalObject`: Opal connection object
- `datasource::String`: Name of the datasource
"""
function opal_datasource(opal::OpalObject, datasource::String)
    return opal_get(opal, "datasource", datasource)
end
