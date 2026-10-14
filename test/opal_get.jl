using Opal
using Test

@testset "login" begin
    opal = opal_login(;
        username="administrator", password="password", url="https://opal-demo.obiba.org"
    )

    opal_get(opal, "project", "CNSIM")
end

println(read(outFile, String))
