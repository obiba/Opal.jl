module Opal

using URIs: URI, escapepath
using Base64: base64encode
using HTTP: request, header
using HTTP.Exceptions: StatusError

include("opal_login.jl")

end
