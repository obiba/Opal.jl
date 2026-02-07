module Opal

using URIs: URI, escapepath
using Base64: base64encode
using HTTP: request, header
using HTTP.Exceptions: StatusError

include("OpalObject.jl")
include("opal_login.jl")
export opal_login

end
