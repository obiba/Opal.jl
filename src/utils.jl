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
"""
function _handleResponse(opal, response)
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
        # Handle attachment - simplified version
        return _handleContent(opal, response)
    else
        return _handleContent(opal, response)
    end
end

"""
Default request response Location header handler.
"""
function _handleResponseLocation(opal, response)
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
function _handleResponseOrCallback(opal, response, callback=nothing)
    if isnothing(callback)
        return _handleResponse(opal, response)
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
