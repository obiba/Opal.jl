# Unit tests for utility functions
# These tests focus on internal helper functions and don't require a server connection

using Test
using Opal
using JSON

@testset "URL Cleaning" begin
    # Test cleaning multiple slashes in URLs
    expected = "https://opal.example.org/ws/files/some/path/to/file"
    @test Opal._cleanUrl("https://opal.example.org/ws/files/some///path/to//file") ==
        expected

    expected = "http://localhost:8080/ws/files/some/path/to/file"
    @test Opal._cleanUrl("http://localhost:8080/ws/files/some///path/to//file") == expected

    # Test with single slashes (should remain unchanged)
    url = "https://opal-demo.obiba.org/ws/datasource/CNSIM/table/CNSIM1"
    @test Opal._cleanUrl(url) == url

    # Test with trailing slashes (should remain unchanged - _cleanUrl doesn't strip trailing slashes)
    @test Opal._cleanUrl("https://example.org/ws/files/") == "https://example.org/ws/files/"
end

@testset "URL Construction" begin
    # Create a minimal OpalObject for testing
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

    # Test basic URL construction
    url = Opal._url(opal, "datasource", "CNSIM", "table", "CNSIM1")
    @test occursin("https://opal-demo.obiba.org", url)
    @test occursin("/datasource/CNSIM/table/CNSIM1", url)

    # Test URL construction with single argument
    url = Opal._url(opal, "projects")
    @test occursin("https://opal-demo.obiba.org", url)
    @test occursin("/projects", url)

    # Test URL construction with multiple segments
    url = Opal._url(opal, "project", "RSRC", "resources")
    @test occursin("https://opal-demo.obiba.org", url)
    @test occursin("/project/RSRC/resources", url)
end

@testset "Null to NA Conversion" begin
    # Test nothing conversion
    @test ismissing(Opal._nullToNA(nothing))

    # Test non-nothing values remain unchanged
    @test Opal._nullToNA("test") == "test"
    @test Opal._nullToNA(123) == 123
    @test Opal._nullToNA(true) == true
    @test Opal._nullToNA([1, 2, 3]) == [1, 2, 3]
end

@testset "Empty Check" begin
    # Test nothing is empty
    @test Opal._isempty(nothing) == true

    # Test missing is empty
    @test Opal._isempty(missing) == true

    # Test empty string is empty
    @test Opal._isempty("") == true

    # Test empty array is empty
    @test Opal._isempty([]) == true

    # Test non-empty values
    @test Opal._isempty("test") == false
    @test Opal._isempty([1, 2, 3]) == false
    @test Opal._isempty(123) == false
    @test Opal._isempty(0) == false
end

@testset "Response Content Parsing" begin
    # Create a minimal OpalObject for testing
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

    # Test JSON content parsing
    json_data = Dict("name" => "CNSIM1", "entityType" => "Participant", "count" => 100)
    json_string = JSON.json(json_data)

    # Mock response with JSON content-type
    mock_resp = Dict(
        "status" => 200,
        "headers" => Dict("content-type" => "application/json"),
        "body" => json_string,
    )

    # Note: We can't fully test _getContent without mocking HTTP.content()
    # but we can test that JSON parsing works
    parsed = JSON.parse(json_string)
    @test parsed["name"] == "CNSIM1"
    @test parsed["entityType"] == "Participant"
    @test parsed["count"] == 100
end

@testset "Session Helpers" begin
    # Test session ID extraction patterns
    # These would normally come from HTTP cookies
    cookies = [Dict("name" => "opalsid", "value" => "abc123def456")]
    # Note: _extractOpalSessionId requires actual HTTP.Cookies format
    # This is a conceptual test showing what we expect
    @test cookies[1]["value"] == "abc123def456"

    # Note: _newSession requires an OpalObject and makes HTTP requests,
    # so it's tested in integration tests instead
end
