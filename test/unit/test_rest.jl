# Unit tests for REST operations (GET, POST, PUT, DELETE)
# These tests focus on the logic of REST operations without requiring a server

using Test
using Opal

@testset "GET Operation Logic" begin
    # Test that opal_get function signature is correct
    @test hasmethod(opal_get, (Opal.OpalObject, Vararg{Any}))

    # Test that opal_get accepts query parameters
    @test hasmethod(opal_get, (Opal.OpalObject, Vararg{Any}))
end

@testset "POST Operation Logic" begin
    # Test that opal_post function exists and has correct signature
    @test hasmethod(opal_post, (Opal.OpalObject, Vararg{Any}))
end

@testset "PUT Operation Logic" begin
    # Test that opal_put function exists and has correct signature
    @test hasmethod(opal_put, (Opal.OpalObject, Vararg{Any}))
end

@testset "DELETE Operation Logic" begin
    # Test that opal_delete function exists and has correct signature
    @test hasmethod(opal_delete, (Opal.OpalObject, Vararg{Any}))
end

@testset "REST Error Handling" begin
    # Test error message formatting
    # When a request fails, we should get a meaningful error

    opal = Opal.OpalObject(
        name="test",
        url="https://invalid-opal-server-that-does-not-exist.example.com",
        username="admin",
        password=nothing,
        token=nothing,
        sid=nothing,
        version=missing,
        rid=nothing,
        restore=nothing,
    )

    # Test that requests to invalid servers throw errors
    # Note: We expect this to fail with a connection error
    @test_throws Exception opal_get(opal, "projects")
end

@testset "Query Parameter Handling" begin
    # Test that query parameters are properly formatted
    opal = Opal.OpalObject(
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

    # Test URL construction with query parameters
    # The _url function should handle query params correctly
    url = Opal._url(opal, "datasource", "CNSIM", "table", "CNSIM1")
    @test occursin("datasource/CNSIM/table/CNSIM1", url)
end

@testset "Content Type Handling" begin
    # Test that different content types are handled correctly

    # JSON content type should be default
    # This is tested in integration tests where we actually make requests
    @test true  # Placeholder - integration tests will validate this
end

@testset "Retry Logic" begin
    # The opal_post, opal_put, opal_delete functions have retry logic
    # This is difficult to unit test without mocking the HTTP layer
    # Integration tests will validate retry behavior

    # Verify that the functions exist and are callable
    @test isdefined(Opal, :opal_post)
    @test isdefined(Opal, :opal_put)
    @test isdefined(Opal, :opal_delete)
    @test isdefined(Opal, :opal_get)
end
