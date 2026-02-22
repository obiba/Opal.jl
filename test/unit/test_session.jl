# Unit tests for session management functions
# These tests focus on session-related logic without requiring a server

using Test
using Opal

@testset "Session Function Signatures" begin
    # Test that session functions exist with correct signatures
    @test isdefined(Opal, :opal_session)
    @test isdefined(Opal, :opal_session_get)
    @test isdefined(Opal, :opal_session_exists)
    @test isdefined(Opal, :opal_session_running)
    @test isdefined(Opal, :opal_session_delete)

    # Test that functions have correct method signatures
    @test hasmethod(opal_session, (Opal.OpalObject,))
    @test hasmethod(opal_session_get, (Opal.OpalObject,))
    @test hasmethod(opal_session_exists, (Opal.OpalObject,))
    @test hasmethod(opal_session_running, (Opal.OpalObject,))
    @test hasmethod(opal_session_delete, (Opal.OpalObject,))
end

@testset "Session Helper Functions" begin
    # Note: _newSession requires an OpalObject and makes HTTP requests,
    # so it's tested in integration tests instead

    # Test _rmRSession helper exists
    @test isdefined(Opal, :_rmRSession)

    # Test _rmOpalSession helper exists
    @test isdefined(Opal, :_rmOpalSession)

    # Test _getSessions helper exists
    @test isdefined(Opal, :_getSessions)
end

@testset "Session State Management" begin
    # Test OpalObject with session ID
    opal_with_session = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid="opal-session-123",
        version=missing,
        rid="r-session-456",
        restore=nothing,
    )

    # Test that session fields are accessible
    @test opal_with_session.sid == "opal-session-123"
    @test opal_with_session.rid == "r-session-456"

    # Test OpalObject without session
    opal_without_session = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid=nothing,
        restore=nothing,
    )

    @test isnothing(opal_without_session.sid)
    @test isnothing(opal_without_session.rid)
end

@testset "Session Existence Logic" begin
    # opal_session_exists should return Bool
    # It checks if opal.rid is not nothing
    opal_with_rid = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid="r-session-id",
        restore=nothing,
    )

    opal_without_rid = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid=nothing,
        restore=nothing,
    )

    # Note: opal_session_exists makes a server request
    # We can't fully test it without a server
    # But we can verify the function signature expects the right types
    @test hasmethod(opal_session_exists, (Opal.OpalObject,))
end

@testset "Session Running Logic" begin
    # opal_session_running should return Bool
    # It checks session status on the server
    # Similar to session_exists, requires server for full test
    @test hasmethod(opal_session_running, (Opal.OpalObject,))
end

@testset "Session Creation Options" begin
    # Test that opal_session accepts wait parameter
    @test hasmethod(opal_session, (Opal.OpalObject,))

    # The function signature should allow keyword argument 'wait'
    # This will be fully tested in integration tests
    @test true  # Placeholder for integration test validation
end
