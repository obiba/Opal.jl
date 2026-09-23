# Utility functions for Opal.jl
# Translated from opalr/R/utils.R and opalr/R/opal.R

using HTTP
using JSON

"""
Extract opalsid from cookie data.
"""
function _extractOpalSessionId(response)
    cookies = HTTP.cookies(response)
    for cookie in cookies
        if cookie.name == "opalsid" && !isnothing(cookie.value)
            return cookie.value
        end
    end
    return nothing
end

function _extractOpalCSRFToken(response)
    cookies = HTTP.cookies(response)
    for cookie in cookies
        if cookie.name == "XSRF-TOKEN" && !isnothing(cookie.value)
            return cookie.value
        end
    end
    return nothing
end

"""
Check if response content is empty.
"""
function _isContentEmpty(content)
    return isnothing(content) ||
           (isa(content, Vector{UInt8}) && length(content) == 0) ||
           (isa(content, String) && isempty(content))
end

"""
Wrapper to get content from HTTP response.
"""
function _getContent(opal, response)
    headers = HTTP.headers(response)
    content_type = nothing
    for (key, value) in headers
        if lowercase(key) == "content-type"
            content_type = value
            break
        end
    end

    if isnothing(content_type)
        return nothing
    elseif content_type == "application/x-protobuf+json"
        return JSON.parse(String(response.body))
    elseif startswith(content_type, "text/")
        return String(response.body)
    elseif startswith(content_type, "image/")
        return response.body
    else
        # Try to parse as JSON if possible
        try
            return JSON.parse(String(response.body))
        catch
            return String(response.body)
        end
    end
end

"""
Handle content from HTTP response.
"""
function _handleContent(opal, response)
    headers = HTTP.headers(response)
    content = _getContent(opal, response)
    content_type = nothing
    for (key, value) in headers
        if lowercase(key) == "content-type"
            content_type = value
            break
        end
    end

    if !isnothing(content_type)
        if occursin("octet-stream", content_type)
            # Deserialize binary content - would need Serialization.jl
            return content
        elseif occursin("text", content_type)
            return String(content)
        end
    end

    return content
end

"""
Handle error response from Opal.
"""
function _handleError(opal, response)
    headers = HTTP.headers(response)
    content = _getContent(opal, response)

    status_msg = "[$(HTTP.Messages.statustext(response.status))]"

    if isnothing(content)
        throw(ErrorException(status_msg))
    end

    if isa(content, Dict)
        if haskey(content, "status")
            if haskey(content, "arguments")
                msg = status_msg * " " * join(content["arguments"], ", ")
            else
                msg = status_msg * " " * content["status"]
            end
            throw(ErrorException(msg))
        end

        if haskey(content, "error")
            if haskey(content, "message")
                throw(ErrorException(content["message"]))
            else
                throw(ErrorException(content["error"]))
            end
        end
    end

    throw(ErrorException(status_msg))
end

"""
Default request response handler.

# Arguments
- `opal::OpalObject`: Opal object
- `response::HTTP.Response`: HTTP response object
"""
function _handleResponse!(opal, response)
    headers = HTTP.headers(response)

    # Extract Opal version
    if ismissing(opal.version)
        for (key, value) in headers
            if lowercase(key) == "x-opal-version"
                opal.version = parse(VersionNumber, value)
                break
            end
        end
    end

    # Extract Opal session ID
    if isnothing(opal.sid)
        opal.sid = _extractOpalSessionId(response)
    end

    if isnothing(opal.csrf)
        opal.csrf = _extractOpalCSRFToken(response)
    end

    if response.status >= 300
        _handleError(opal, response)
    end

    # Check for attachment (file download)
    disposition = nothing
    for (key, value) in headers
        if lowercase(key) == "content-disposition"
            disposition = value
            break
        end
    end

    if !isnothing(disposition) && occursin("attachment", disposition)
        return _handleAttachment(opal, response, disposition)
    else
        return _handleContent(opal, response)
    end
end

"""
Default request response Location header handler.
"""
function _handleResponseLocation!(opal, response)
    headers = HTTP.headers(response)

    # Extract Opal version
    if ismissing(opal.version)
        for (key, value) in headers
            if lowercase(key) == "x-opal-version"
                opal.version = parse(VersionNumber, value)
                break
            end
        end
    end

    # Extract Opal session ID
    if isnothing(opal.sid)
        opal.sid = _extractOpalSessionId(response)
    end

    if isnothing(opal.csrf)
        opal.csrf = _extractOpalCSRFToken(response)
    end

    if response.status >= 300
        _handleError(opal, response)
    end

    # Extract Location header
    for (key, value) in headers
        if lowercase(key) == "location"
            # Extract path after /ws/
            idx = findfirst("/ws/", value)
            if !isnothing(idx)
                return value[(idx[end] + 1):end]
            else
                return value
            end
        end
    end

    return nothing
end

"""
Process response with default handler or the provided one.
"""
function _handleResponseOrCallback!(opal, response, callback=nothing)
    if isnothing(callback)
        return _handleResponse!(opal, response)
    else
        return callback(opal, response)
    end
end

"""
Convert null to missing.
"""
function _nullToNA(x)
    return isnothing(x) ? missing : x
end

"""
Check if value is empty.
"""
function _isempty(value)
    if isnothing(value) || ismissing(value)
        return true
    end
    if isa(value, String) && isempty(value)
        return true
    end
    if isa(value, Vector) && isempty(value)
        return true
    end
    return false
end

"""
Extract absolute path to the PEM file.
"""
function _getPEMFilePath(pem; directory="~/.ssh")
    path = pem
    expanded = expanduser(pem)

    # Check if file exists (absolute path)
    if isfile(expanded)
        return expanded
    end

    # Check file relative to given directory
    dir_path = expanduser(joinpath(directory, pem))
    if isfile(dir_path)
        return dir_path
    end

    # Check file relative to working directory
    cwd_path = joinpath(pwd(), pem)
    if isfile(cwd_path)
        return cwd_path
    end

    # Return original path if none found
    return path
end

"""
Function to replace duplicated slashes but preserve '://'.
"""
function _cleanUrl(url)
    return replace(url, r"(?<!:)//+" => "/")
end

"""
Create a new R session in Opal.
"""
function _newSession(opal; restore=nothing, profile=nothing, wait=true)
    query = Dict{String,Any}()
    if !isnothing(restore)
        query["restore"] = restore
    end
    if !isnothing(profile)
        query["profile"] = profile
    end
    query["wait"] = wait ? "true" : "false"

    resp = opal_post(opal, opal.context, "sessions"; query=query)

    if isa(resp, Dict) && haskey(resp, "id")
        return resp["id"]
    else
        throw(ErrorException("Failed to create R session"))
    end
end

"""
Remove a R session from Opal.
"""
function _rmRSession(opal; save=false)
    if !isnothing(opal.rid)
        if (isa(save, Bool) && save) || isa(save, String)
            saveId = save
            if isa(save, Bool) && save
                saveId = opal.rid
            end
            opal_delete(
                opal, opal.context, "session", opal.rid; query=Dict("save" => saveId)
            )
            if saveId != save
                return saveId
            end
        else
            opal_delete(opal, opal.context, "session", opal.rid)
        end
    end
    return nothing
end

"""
Remove an Opal session (logout).
"""
function _rmOpalSession(opal)
    if !isnothing(opal.sid)
        opal_delete(opal, "auth", "session", opal.sid)
    end
    return nothing
end

"""
Get all R sessions in Opal.
"""
function _getSessions(opal)
    return opal_get(opal, opal.context, "sessions")
end

"""
Compare Opal version with the provided one. Note that a request must have been
done in order to have a non-missing Opal version.

# Arguments
- `opal::OpalObject`: Opal object
- `version::String`: The semantic version string to be compared

# Returns
- `>0` if Opal version is more recent, `0` if equals, `<0` otherwise
"""
function _versionCompare(opal, version::String)
    if ismissing(opal.version)
        throw(ErrorException("opal version is not set"))
    end
    ov = VersionNumber(split(string(opal.version), "-")[1])
    sv = VersionNumber(version)
    if ov == sv
        return 0
    end
    return ov < sv ? -1 : 1
end

"""
Simple transformation function of a dictionary into a JSON object/array string.
"""
function _listToJson(value)
    valueToString = function (v)
        if v isa AbstractDict || v isa AbstractVector
            return _listToJson(v)
        elseif v isa Bool
            return v ? "true" : "false"
        else
            return "\"$(v)\""
        end
    end
    if value isa AbstractDict
        str = ""
        for (name, v) in value
            if !isempty(str)
                str = str * ","
            end
            str = str * "\"$(name)\": " * valueToString(v)
        end
        return "{$(str)}"
    elseif value isa AbstractVector
        str = ""
        for v in value
            if !isempty(str)
                str = str * ","
            end
            str = str * valueToString(v)
        end
        return "[$(str)]"
    else
        return valueToString(value)
    end
end

"""
Turn expression into character strings.
"""
function _deparse(expr)
    return expr isa String ? expr : string(expr)
end

"""
Extract label for locale. If not found, fallback to undefined language label (if any).
"""
function _extractLabel(
    locale::String="en", labels::AbstractVector=[]; localeKey="locale", valueKey="value"
)
    if isempty(labels)
        return missing
    end
    label = missing
    label_und = missing
    for l in labels
        if !haskey(l, localeKey)
            label_und = l[valueKey]
        elseif l[localeKey] == locale
            label = l[valueKey]
        end
    end
    return ismissing(label) ? label_und : label
end

"""
Split an attribute key of the form "namespace::name", "name" or "name:locale".
"""
function _splitAttributeKey(key)
    str = split(key, ":")
    namespace = nothing
    name = nothing
    loc = nothing
    if length(str) > 2 && str[2] == ""
        namespace = str[1]
        name = str[3]
        if length(str) == 4
            loc = str[4]
        end
    else
        name = str[1]
        if length(str) == 2
            loc = str[2]
        end
    end
    rval = Dict{String,Any}()
    if !isnothing(namespace)
        rval["namespace"] = namespace
    end
    rval["name"] = name
    if !isnothing(loc)
        rval["locale"] = loc
    end
    return rval
end

"""
Normalize a value to a string, "N/A" when empty.
"""
function _norm2nastr(value)
    return _isempty(value) ? "N/A" : string(value)
end

"""
Extract the text of the item matching the given locale.
"""
function _localized2str(item, locale)
    for msg in item
        if msg["locale"] == locale
            return msg["text"]
        end
    end
    return ""
end

"""
Merge two vectors of characters, joining non-missing values with " | ".
"""
function _mergeCharVectors(left, right)
    n = max(length(left), length(right))
    result = Union{Missing,String}[i <= length(left) ? left[i] : missing for i in 1:n]
    for i in 1:n
        oval = i <= length(left) ? left[i] : missing
        nval = i <= length(right) ? right[i] : missing
        if !ismissing(nval) && !isnothing(nval)
            result[i] = ismissing(oval) ? string(nval) : "$(oval) | $(nval)"
        end
    end
    return result
end

"""
Guess the MIME type of a file from its extension.
"""
function _guessType(filename)
    ext = lowercase(splitext(filename)[2])
    types = Dict(
        ".csv" => "text/csv",
        ".tsv" => "text/tab-separated-values",
        ".txt" => "text/plain",
        ".html" => "text/html",
        ".json" => "application/json",
        ".xml" => "application/xml",
        ".pdf" => "application/pdf",
        ".zip" => "application/zip",
        ".sav" => "application/x-spss-sav",
        ".zsav" => "application/x-spss-sav",
        ".dta" => "application/x-stata-dta",
        ".xpt" => "application/x-sas-xport",
        ".sas7bdat" => "application/x-sas-data",
    )
    return get(types, ext, "application/octet-stream")
end

"""
Handle response attachment.
"""
function _handleAttachment(opal, response, disposition)
    headers = HTTP.headers(response)
    content = _getContent(opal, response)

    filename = split(disposition, "\"")[2]
    filetype = _guessType(filename)
    content_type = nothing
    for (key, value) in headers
        if lowercase(key) == "content-type"
            content_type = value
            break
        end
    end

    if isa(content, Vector{UInt8})
        if occursin("text/", string(content_type)) ||
            (occursin("application/", string(content_type)) && occursin("text/", filetype))
            return String(content)
        else
            return content
        end
    elseif occursin("text/", string(content_type))
        return string(content)
    else
        return content
    end
end

"""
Print a concise description of the Opal object.
"""
function Base.show(io::IO, ::MIME"text/plain", o::OpalObject)
    println(io, "url: ", o.url)
    println(io, "name: ", o.name)
    println(io, "version: ", o.version)
    println(io, "username: ", o.username)
    if !isnothing(o.rid)
        println(io, "rid: ", o.rid)
    end
    if !isnothing(o.profile)
        println(io, "profile: ", o.profile)
    end
    if !isnothing(o.restore)
        println(io, "restore: ", o.restore)
    end
end

"""
    opal_as_md_table(table; icons=true, digits=7, col_names=nothing, align=nothing, caption=nothing) -> String

Get a Markdown table rendition of the provided table (data frame), with bootstrap
glyph icons for boolean values.
"""
function opal_as_md_table(
    table::DataFrame;
    icons::Bool=true,
    digits::Int=7,
    col_names=nothing,
    align=nothing,
    caption=nothing,
)
    asIcon = function (a)
        if a isa Bool || ismissing(a) || (a isa AbstractString && (a == "true" || a == "false"))
            truthy = a isa Bool ? a : (ismissing(a) ? false : (a == "true"))
            if truthy
                return "<span class=\"glyphicon glyphicon-ok alert-success\"></span>"
            else
                return "<span class=\"glyphicon glyphicon-remove alert-error\"></span>"
            end
        end
        return a
    end

    formatValue = function (v)
        if ismissing(v) || isnothing(v)
            return ""
        elseif v isa AbstractFloat
            return string(round(v; digits=digits))
        else
            return string(v)
        end
    end

    ncol = size(table, 2)
    header = isnothing(col_names) ? names(table) : String.(collect(col_names))
    separator = String[]
    for i in 1:ncol
        a = isnothing(align) ? nothing : align[min(i, length(align))]
        if a == "c"
            push!(separator, ":---:")
        elseif a == "r"
            push!(separator, "---:")
        else
            push!(separator, ":---")
        end
    end

    lines = String[]
    if !isnothing(caption)
        push!(lines, "Table: $(caption)")
    end
    push!(lines, "| " * join(header, " | ") * " |")
    push!(lines, "|" * join(separator, "|") * "|")
    for r in 1:size(table, 1)
        values = Any[table[r, c] for c in 1:ncol]
        if icons
            values = [asIcon(a) for a in values]
        end
        push!(lines, "| " * join([formatValue(v) for v in values], " | ") * " |")
    end
    return join(lines, "\n")
end
