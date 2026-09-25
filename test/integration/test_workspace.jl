# Integration tests for workspace operations
# Requires a live Opal server (set OPAL_TEST_URL to run)

using Test
using Opal

@testset "Workspace Operations" begin
    check_skip() && return nothing

    o = make_test_opal()

    wsname = random_workspace_name()

    # save the workspace (requires an R session)
    id = opal_workspace_save(o, wsname)
    @test id == wsname || id == o.rid

    # list the workspaces
    wss = opal_workspaces(o)
    @test isa(wss, DataFrame)
    if !isnothing(wss)
        @test wsname in wss.name
    end

    # restore the workspace (Opal 4.5+)
    if !ismissing(o.version) && Opal._versionCompare(o, "4.5") >= 0
        opal_workspace_restore(o, wsname)
        @test !isnothing(o.rid)
    end

    # remove the workspace
    opal_workspace_rm(o, wsname)
    wss = opal_workspaces(o)
    if !isnothing(wss)
        @test wsname ∉ wss.name
    end

    opal_logout(o)
end
