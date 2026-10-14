# Integration tests for login and logout operations
# These tests require a live Opal server (set OPAL_TEST_URL to run)

using Test
using Opal
using DataFrames
include("../test_helpers.jl")

@testset "Login with Username/Password" begin
    check_skip() && return nothing

    username, password = get_test_credentials()
    url = get_test_url()

    # Test successful login
    o = opal_login(; username=username, password=password, url=url)

    @test isa(o, Opal.OpalObject)
    @test o.username == username
    @test o.url == url
    @test !isnothing(o.name)

    # Clean up
    opal_logout(o)
end

@testset "Login with Token" begin
    check_skip() && return nothing

    # Note: Token login requires a valid token
    # This test is skipped if OPAL_TEST_TOKEN is not set
    if !haskey(ENV, "OPAL_TEST_TOKEN")
        @test_skip "Token login test requires OPAL_TEST_TOKEN environment variable"
        return nothing
    end

    token = ENV["OPAL_TEST_TOKEN"]
    url = get_test_url()

    o = opal_login(; token=token, url=url)

    @test isa(o, Opal.OpalObject)
    @test o.token == token
    @test o.url == url
    @test !isnothing(o.name)

    # Clean up
    opal_logout(o)
end

@testset "Logout Single Connection" begin
    check_skip() && return nothing

    o = make_test_opal()

    @test isa(o, Opal.OpalObject)

    # Logout should succeed
    opal_logout(o)

    # After logout, the connection should be closed
    # Attempting operations should fail
    @test_throws Exception opal_get(o, "projects")
end

@testset "Logout Multiple Connections" begin
    check_skip() && return nothing

    # Create multiple connections
    o1 = make_test_opal()
    o2 = make_test_opal()

    @test isa(o1, Opal.OpalObject)
    @test isa(o2, Opal.OpalObject)

    # Logout multiple connections
    opal_logout([o1, o2])

    # Both connections should be closed
    @test_throws Exception opal_get(o1, "projects")
    @test_throws Exception opal_get(o2, "projects")
end

@testset "Login Error Handling" begin
    check_skip() && return nothing

    url = get_test_url()

    # Test login with invalid credentials
    @test_throws Exception opal_login(;
        username="invalid_user", password="wrong_password", url=url
    )

    # Test login with invalid URL
    @test_throws Exception opal_login(;
        username="admin", password="password", url="https://invalid-server.example.com"
    )
end

@testset "Session Cleanup After Logout" begin
    check_skip() && return nothing

    username, password = get_test_credentials()
    url = get_test_url()

    # Login with save=false (no workspace save on logout)
    o = opal_login(; username=username, password=password, url=url)

    # Get initial session ID (if any)
    initial_sid = o.sid
    initial_rid = o.rid

    # Logout without saving workspace
    opal_logout(o; save=false)

    # After logout, attempting to use the connection should fail
    @test_throws Exception opal_get(o, "projects")
end

@testset "Multiple Login/Logout Cycles" begin
    check_skip() && return nothing

    username, password = get_test_credentials()
    url = get_test_url()

    # Test multiple login/logout cycles
    for i in 1:3
        o = opal_login(; username=username, password=password, url=url)
        @test isa(o, Opal.OpalObject)

        # Verify we can make a request
        projects = opal_get(o, "projects")
        @test isa(projects, Union{Vector,Dict})

        opal_logout(o)
    end
end

@testset "Logout With Saved Workspace" begin
    check_skip() && return nothing

    username, password = get_test_credentials()
    url = get_test_url()

    o = opal_login(; username=username, password=password, url=url)
    ws_id = nothing

    try
        # create an R session and assign a symbol so the workspace is
        # worth saving
        opal_session(o)
        opal_assign_script(o, "keepme", "function(x) x + 1")

        # logout with save=true: must return the workspace id (the rid)
        # instead of nothing
        ws_id = opal_logout(o; save=true)
        @test !isnothing(ws_id)
        @test ws_id isa String

        # the saved workspace must be listed (opal_workspaces returns a
        # DataFrame with a name column; the workspace name is the rid)
        o2 = opal_login(; username=username, password=password, url=url)
        try
            workspaces = opal_workspaces(o2)
            @test !isnothing(workspaces)
            @test workspaces isa DataFrame
            @test ws_id in workspaces.name

            # and restorable in a new session (Opal 4.5+; older servers
            # only warn)
            if ismissing(o2.version) || Opal._versionCompare(o2, "4.5") >= 0
                opal_workspace_restore(o2, ws_id)
                opal_session(o2)
                symbols = opal_symbols(o2)
                symbols_list(s) = s isa AbstractVector ? s : [string(s)]
                @test "keepme" in symbols_list(symbols)
            else
                @test_skip "Workspace restore requires Opal 4.5+"
            end

            # clean up the workspace
            opal_workspace_rm(o2, ws_id)
        finally
            opal_logout(o2)
        end
    finally
        if ws_id isa String
            # make sure the workspace does not leak if a test failed early
            oc = opal_login(; username=username, password=password, url=url)
            try
                opal_workspace_rm(oc, ws_id)
            catch
                # ignore cleanup errors
            finally
                opal_logout(oc)
            end
        end
    end
end
