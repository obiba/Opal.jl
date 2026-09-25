# Unit tests for workspace operations
# These tests focus on function signatures, version guards and error paths
# without requiring a server

using Test
using Opal
using DataFrames

@testset "Workspace Operations Logic" begin
    @test hasmethod(opal_workspaces, (Opal.OpalObject,))
    @test hasmethod(opal_workspace_rm, (Opal.OpalObject, String))
    @test hasmethod(opal_workspace_save, (Opal.OpalObject,))
    @test hasmethod(opal_workspace_restore, (Opal.OpalObject, String))
end

@testset "Workspace Version Guard" begin
    # workspaces require Opal 2.6 or higher: guards warn instead of failing
    opal = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "2.5"),
    )
    @test_logs (:warn,) begin
        @test isnothing(opal_workspace_save(opal, "test"))
    end

    # restore is not available for opal < 4.5: warn and return nothing
    opal = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="test-user",
        version=parse(VersionNumber, "4.0"),
    )
    @test_logs (:warn,) begin
        @test isnothing(opal_workspace_restore(opal, "test"))
    end
end

@testset "Workspace RM Errors" begin
    # Missing user name raises an error before any request is made
    opal = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="",
        version=parse(VersionNumber, "5.1"),
    )
    @test_throws ErrorException opal_workspace_rm(opal, "test"; user=nothing)
end
