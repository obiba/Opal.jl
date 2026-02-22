# Integration tests for session management operations
# These tests require a live Opal server (set OPAL_TEST_URL to run)

using Test
using Opal
include("../test_helpers.jl")

@testset "Session Creation" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Initially, there should be no R session
        @test isnothing(o.rid)

        # Create a session
        session_id = opal_session(o; wait=true)

        @test !isnothing(session_id)
        @test isa(session_id, String)

        # The OpalObject should now have a session ID
        @test !isnothing(o.rid)
        @test o.rid == session_id
    finally
        opal_logout(o)
    end
end

@testset "Session Get Details" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Create a session first
        session_id = opal_session(o; wait=true)

        # Get session details
        session_info = opal_session_get(o)

        @test !isnothing(session_info)
        @test isa(session_info, Dict)
        @test haskey(session_info, "id")
        @test session_info["id"] == session_id
    finally
        opal_logout(o)
    end
end

@testset "Session Existence Check" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Initially, no session should exist
        @test !opal_session_exists(o)

        # Create a session
        session_id = opal_session(o; wait=true)

        # Now session should exist
        @test opal_session_exists(o)
        @test o.rid == session_id
    finally
        opal_logout(o)
    end
end

@testset "Session Running Status" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Create a session
        session_id = opal_session(o; wait=true)

        # Session should be running
        @test opal_session_running(o)
    finally
        opal_logout(o)
    end
end

@testset "Session Deletion" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Create a session
        session_id = opal_session(o; wait=true)
        @test opal_session_exists(o)

        # Delete the session
        opal_session_delete(o)

        # Session should no longer exist
        @test !opal_session_exists(o)
        @test isnothing(o.rid)
    finally
        # Clean up in case session still exists
        try
            opal_logout(o)
        catch
            # Ignore errors during cleanup
        end
    end
end

@testset "No Session Created for Table Operations" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Check a table exists (should not create session)
        exists = opal_table_exists(o, "CNSIM", "CNSIM1")
        @test isa(exists, Bool)

        # No R session should have been created
        @test isnothing(o.rid)

        # Get table metadata (should not create session)
        table_info = opal_table(o, "CNSIM", "CNSIM1")
        @test isa(table_info, Dict)

        # Still no R session
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Session Reuse" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Create a session
        session_id1 = opal_session(o; wait=true)
        @test !isnothing(session_id1)

        # Calling opal_session again should return the same session
        session_id2 = opal_session(o; wait=true)
        @test session_id1 == session_id2
        @test o.rid == session_id1
    finally
        opal_logout(o)
    end
end

@testset "Multiple Sessions Not Allowed" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Create a session
        session_id = opal_session(o; wait=true)
        @test !isnothing(session_id)
        @test o.rid == session_id

        # The same OpalObject should maintain the same session
        new_session_id = opal_session(o; wait=true)
        @test new_session_id == session_id
    finally
        opal_logout(o)
    end
end

@testset "Session Without Wait Parameter" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Create session with wait=false (async)
        session_id = opal_session(o; wait=false)
        @test !isnothing(session_id)

        # Give it a moment to start
        sleep(1)

        # Session should exist
        @test opal_session_exists(o)
    finally
        opal_logout(o)
    end
end
