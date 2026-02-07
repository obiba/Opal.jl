using Opal
using Opal: OpalObject
using Test

@testset "login" begin
    opal = opal_login(;
        username="administrator", password="password", url="https://opal-demo.obiba.org"
    )

    @test isa(opal, OpalObject)
end
