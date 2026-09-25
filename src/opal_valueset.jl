"""
    opal_variable(opal, datasource, table, variable)

Get a variable of a table.

# Arguments
- `opal::OpalObject`: Opal connection object
- `datasource::String`: Name of the datasource
- `table::String`: Name of the table in the datasource
- `variable::String`: Name of the variable in the table
"""
function opal_variable(
    opal::OpalObject, datasource::String, table::String, variable::String
)
    return opal_get(opal, "datasource", datasource, "table", table, "variable", variable)
end

"""
    opal_variable_summary(opal, datasource, table, variable; cached=true, nature=nothing)

Get summary statistics of a variable of a table.

# Arguments
- `opal::OpalObject`: Opal connection object
- `datasource::String`: Name of the datasource
- `table::String`: Name of the table in the datasource
- `variable::String`: Name of the variable in the table
- `cached::Bool=true`: Get cached summary if exists. When false, the cached summary is evicted and replaced by the newly calculated one
- `nature::Union{Nothing, String}=nothing`: Force summary nature, independently from the variable. Possible values are: CATEGORICAL, CONTINUOUS, TEMPORAL, GEO, BINARY, UNDETERMINED
"""
function opal_variable_summary(
    opal::OpalObject,
    datasource::String,
    table::String,
    variable::String;
    cached::Bool=true,
    nature::Union{Nothing,String}=nothing,
)
    q = Dict{String,Any}("fullIfCached" => true, "resetCache" => !cached)
    if !isnothing(nature)
        q["nature"] = nature
    end
    return opal_get(
        opal,
        "datasource",
        datasource,
        "table",
        table,
        "variable",
        variable,
        "summary";
        query=q,
    )
end

"""
    opal_attribute_values(attributes; namespace=nothing, name="label")

Get a vector of attribute values (for each locale) matching the given attribute
namespace and name. Vector is empty if no such attribute is found.

# Arguments
- `attributes`: A vector of attributes, usually variable or category attributes
- `namespace::Union{Nothing, String}=nothing`: Optional attribute namespace
- `name::String="label"`: Required attribute name
"""
function opal_attribute_values(attributes; namespace=nothing, name::String="label")
    rval = Any[]
    if isempty(attributes)
        return rval
    end
    for attr in attributes
        nvalue = get(attr, "value", nothing)
        if get(attr, "name", nothing) == name &&
            get(attr, "namespace", nothing) == namespace &&
            (nvalue isa AbstractString ? !isempty(nvalue) : !isnothing(nvalue))
            locale = get(attr, "locale", nothing)
            if isnothing(locale)
                push!(rval, nvalue)
            else
                push!(rval, "[$(locale)] $(nvalue)")
            end
        end
    end
    return rval
end

"""
    opal_valueset(opal, datasource, table, identifier)

Get the values of an entity in a table.

# Arguments
- `opal::OpalObject`: Opal connection object
- `datasource::String`: Name of the datasource
- `table::String`: Name of the table in the datasource
- `identifier::String`: Entity identifier
"""
function opal_valueset(
    opal::OpalObject, datasource::String, table::String, identifier::String
)
    response = opal_get(
        opal, "datasource", datasource, "table", table, "valueSet", identifier
    )
    valueset = Dict{String,Any}()
    i = 1
    variables = get(response, "variables", [])
    for variable in variables
        valueSets = get(response, "valueSets", [])
        if isempty(valueSets)
            break
        end
        values = get(valueSets[1], "values", [])
        if i > length(values)
            break
        end
        value = values[i]["value"]
        if value isa AbstractVector
            valueset[variable] = map(v -> v["value"], value)
        elseif value isa AbstractDict
            valueset[variable] = value
        else
            valueset[variable] = value
        end
        i += 1
    end
    return valueset
end

"""
    opal_variables(opal, datasource, table; locale="en", df=true)

Get variables of a table.

# Arguments
- `opal::OpalObject`: Opal connection object
- `datasource::String`: Name of the datasource
- `table::String`: Name of the table in the datasource
- `locale::String="en"`: The language for labels
- `df::Bool=true`: Return a data frame
"""
function opal_variables(
    opal::OpalObject, datasource::String, table::String; locale::String="en", df::Bool=true
)
    res = opal_get(opal, "datasource", datasource, "table", table, "variables")
    if !df
        return res
    end
    if isnothing(res) || isempty(res)
        return DataFrame()
    end
    name = String[]
    ds = String[]
    tbl = String[]
    label = Union{Missing,String}[]
    description = Union{Missing,String}[]
    entityType = Union{Missing,String}[]
    valueType = Union{Missing,String}[]
    unit = Union{Missing,String}[]
    referencedEntityType = Union{Missing,String}[]
    mimeType = Union{Missing,String}[]
    repeatable = Bool[]
    occurrenceGroup = Union{Missing,String}[]
    index = Union{Missing,Int}[]
    categories = Union{Missing,String}[]
    categories_missing = Union{Missing,String}[]
    categories_label = Union{Missing,String}[]
    annotations = Dict{String,Vector{Union{Missing,String}}}()

    for (idx, item) in enumerate(res)
        push!(name, get(item, "name", ""))
        push!(ds, datasource)
        push!(tbl, table)
        attributes = get(item, "attributes", [])
        labels = [a for a in attributes if get(a, "name", nothing) == "label"]
        push!(label, _extractLabel(locale, labels))
        descriptions = [a for a in attributes if get(a, "name", nothing) == "description"]
        push!(description, _extractLabel(locale, descriptions))
        annots = [a for a in attributes if haskey(a, "namespace")]
        for annot in annots
            key = "$(annot["namespace"]).$(annot["name"])"
            if !haskey(annotations, key)
                annotations[key] = Union{Missing,String}[missing for _ in 1:length(res)]
            end
            annotations[key][idx] = get(annot, "value", missing)
        end
        push!(entityType, get(item, "entityType", missing))
        push!(valueType, get(item, "valueType", missing))
        push!(unit, _nullToNA(get(item, "unit", nothing)))
        push!(referencedEntityType, _nullToNA(get(item, "referencedEntityType", nothing)))
        push!(mimeType, _nullToNA(get(item, "mimeType", nothing)))
        push!(repeatable, haskey(item, "repeatable"))
        push!(occurrenceGroup, _nullToNA(get(item, "occurrenceGroup", nothing)))
        idxcol = get(item, "index", missing)
        push!(index, isnothing(idxcol) ? missing : idxcol)
        cats = get(item, "categories", nothing)
        if cats isa AbstractVector && !isempty(cats)
            push!(categories, join(map(c -> get(c, "name", ""), cats), "|"))
            push!(categories_missing, join(map(c -> c["isMissing"] ? "T" : "F", cats), "|"))
            push!(
                categories_label,
                join(
                    map(
                        c -> begin
                            cattrs = get(c, "attributes", nothing)
                            if cattrs isa AbstractVector
                                clabels = [
                                    a for a in cattrs if get(a, "name", nothing) == "label"
                                ]
                                if !isempty(clabels)
                                    clabel = _extractLabel(locale, clabels)
                                    return ismissing(clabel) ? "" : clabel
                                end
                            end
                            return ""
                        end,
                        cats,
                    ),
                    "|",
                ),
            )
        else
            push!(categories, missing)
            push!(categories_missing, missing)
            push!(categories_label, missing)
        end
    end

    df = DataFrame(
        "name" => name,
        "datasource" => ds,
        "table" => tbl,
        "label" => label,
        "description" => description,
        "entityType" => entityType,
        "valueType" => valueType,
        "unit" => unit,
        "referencedEntityType" => referencedEntityType,
        "mimeType" => mimeType,
        "repeatable" => repeatable,
        "occurrenceGroup" => occurrenceGroup,
        "index" => index,
        "categories" => categories,
        "categories.missing" => categories_missing,
        "categories.label" => categories_label,
    )
    for (col, values) in annotations
        df[!, col] = values
    end
    return df
end
