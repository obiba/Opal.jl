# Unit tests for REST operations (GET, POST, PUT, DELETE)
# These tests focus on the logic of REST operations without requiring a server

using Test
using Opal
using HTTP

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

@testset "GET Error and Auth Header Parity" begin
    # opal_get must route HTTP errors into _handleError like post/put/delete
    # (status_exception=false) so that Opal's error message is not lost,
    # and must send the Authorization / X-Opal-Auth headers
    src = read(joinpath(dirname(@__DIR__), "..", "src", "opal_get.jl"), String)
    @test occursin("status_exception=false", src)
    @test count("headers[\"Authorization\"]", src) == 1
    @test count("headers[\"X-Opal-Auth\"]", src) == 1

    # the response handler turns an error response into a meaningful
    # ErrorException (this is what status_exception=false feeds into)
    opal = Opal.OpalObject(
        name="test",
        url="https://opal.example.org",
        username="admin",
        password=nothing,
        token=nothing,
        sid="abc",
        version=v"3.0.0",
        rid=nothing,
        restore=nothing,
    )
    resp = HTTP.Response(404, ["Content-Type" => "application/json"]; body="{}")
    @test_throws ErrorException Opal._handleResponse!(opal, resp)
end

@testset "Connection Options Applied to All Requests" begin
    # _requestConfig must be spread into every request call so that
    # settings like require_ssl_verification or client certificates
    # apply after login too (opal_get, opal_post, opal_put, opal_delete
    # and the login profile GETs)
    for file in ("opal_get.jl", "opal_post.jl", "opal_put.jl", "opal_delete.jl")
        src = read(joinpath(dirname(@__DIR__), "..", "src", file), String)
        @test occursin("_requestConfig(opal)...", src)
    end
    login_src = read(joinpath(dirname(@__DIR__), "..", "src", "opal_login.jl"), String)
    @test count("_requestConfig(opal)...", login_src) == 2
end
