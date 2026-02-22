module Opal

using URIs: URI, escapepath
using Base64: base64encode
using HTTP: request, header
using HTTP.Exceptions: StatusError
using JSON

include("OpalObject.jl")
include("utils.jl")

include("opal_login.jl")
export opal_login

include("opal_logout.jl")
export opal_logout

include("opal_get.jl")
export opal_get

include("opal_post.jl")
export opal_post

include("opal_put.jl")
export opal_put

include("opal_delete.jl")
export opal_delete

include("opal_session.jl")
export opal_session
export opal_session_get
export opal_session_exists
export opal_session_running
export opal_session_delete

include("opal_table.jl")
export opal_table
export opal_table_exists
export opal_table_delete
export opal_table_create
export opal_table_truncate
export opal_table_get

include("opal_resource.jl")
export opal_resources
export opal_resource
export opal_resource_exists
export opal_resource_get
export opal_resource_create
export opal_resource_extension_create
export opal_resource_delete

end
