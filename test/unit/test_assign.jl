# Unit tests for assignment operations
# These tests focus on function signatures and error paths without requiring a server

using Test
using Opal

@testset "Assignment Operations Logic" begin
    @test hasmethod(opal_assign, (Opal.OpalObject, String, Any))
    @test hasmethod(opal_assign_table, (Opal.OpalObject, String, String))
    @test hasmethod(opal_assign_table_tibble, (Opal.OpalObject, String, String))
    @test hasmethod(opal_assign_script, (Opal.OpalObject, String, String))
    @test hasmethod(opal_assign_resource, (Opal.OpalObject, String, String))
end

@testset "Assign Resource Version Guard" begin
    # resources require Opal 3.0 or higher
    opal = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "2.9"),
    )
    @test_throws ErrorException opal_assign_resource(opal, "D", "datashield.CNSIM1r")
end
