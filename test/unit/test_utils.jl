# Unit tests for utility functions
# These tests focus on internal helper functions and don't require a server connection

using Test
using Opal
using HTTP
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

@testset "Session Cookie Extraction" begin
    response = HTTP.Response(
        200,
        [
            "Set-Cookie" => "opalsid=abc123; Path=/",
            "Set-Cookie" => "XSRF-TOKEN=tok456; Path=/",
        ],
    )
    @test Opal._extractOpalSessionId(response) == "abc123"
    @test Opal._extractOpalCSRFToken(response) == "tok456"

    # no cookies returns nothing
    response = HTTP.Response(200)
    @test isnothing(Opal._extractOpalSessionId(response))
    @test isnothing(Opal._extractOpalCSRFToken(response))
end

@testset "Version Compare" begin
    opal = Opal.OpalObject(version=parse(VersionNumber, "5.1.4"))
    @test Opal._versionCompare(opal, "5.1") == 1
    @test Opal._versionCompare(opal, "5.1.4") == 0
    @test Opal._versionCompare(opal, "5.0") == 1
    @test Opal._versionCompare(opal, "5.2") == -1
    @test Opal._versionCompare(opal, "3.2") == 1

    # prerelease versions are compared without their pre-release suffix
    opal = Opal.OpalObject(version=parse(VersionNumber, "5.1.4-rc1"))
    @test Opal._versionCompare(opal, "5.1.4") == 0
    @test Opal._versionCompare(opal, "5.1.3") == 1
    @test Opal._versionCompare(opal, "5.1.5") == -1

    # missing version raises an error
    opal = Opal.OpalObject(version=missing)
    @test_throws ErrorException Opal._versionCompare(opal, "5.1")
end

@testset "List To JSON" begin
    @test Opal._listToJson(Dict("a" => "b")) == "{\"a\": \"b\"}"
    @test Opal._listToJson(["x", "y"]) == "[\"x\",\"y\"]"
    @test Opal._listToJson(Dict("n" => true)) == "{\"n\": true}"
    @test Opal._listToJson(Dict("n" => false)) == "{\"n\": false}"
    @test Opal._listToJson(42) == "\"42\""
    @test Opal._listToJson("v") == "\"v\""
end

@testset "Deparse" begin
    @test Opal._deparse("c(1, 2, 3)") == "c(1, 2, 3)"
    @test Opal._deparse(:(a + b)) == "a + b"
end

@testset "Extract Label" begin
    labels = [
        Dict("name" => "label", "locale" => "en", "value" => "Age"),
        Dict("name" => "label", "locale" => "fr", "value" => "Âge"),
    ]
    @test Opal._extractLabel("en", labels) == "Age"
    @test Opal._extractLabel("fr", labels) == "Âge"
    # fallback to undefined locale label
    labels = [Dict("name" => "label", "value" => "Age")]
    @test Opal._extractLabel("en", labels) == "Age"
    # no labels
    @test ismissing(Opal._extractLabel("en", []))
end

@testset "Split Attribute Key" begin
    attr = Opal._splitAttributeKey("ns::name")
    @test attr["namespace"] == "ns"
    @test attr["name"] == "name"
    @test !haskey(attr, "locale")

    attr = Opal._splitAttributeKey("ns::name:en")
    @test attr["namespace"] == "ns"
    @test attr["name"] == "name"
    @test attr["locale"] == "en"

    attr = Opal._splitAttributeKey("label")
    @test !haskey(attr, "namespace")
    @test attr["name"] == "label"
    @test !haskey(attr, "locale")

    attr = Opal._splitAttributeKey("label:en")
    @test !haskey(attr, "namespace")
    @test attr["name"] == "label"
    @test attr["locale"] == "en"
end

@testset "Merge Char Vectors" begin
    left = ["a", "b"]
    right = ["x | y", "c"]
    merged = Opal._mergeCharVectors(left, right)
    @test merged[1] == "a | x | y"
    @test merged[2] == "b | c"
end

@testset "Norm to NA String" begin
    @test Opal._norm2nastr("value") == "value"
    @test Opal._norm2nastr(nothing) == "N/A"
    @test Opal._norm2nastr("") == "N/A"
    @test Opal._norm2nastr(123) == "123"
end

@testset "Localize to String" begin
    item = [
        Dict("locale" => "en", "text" => "hello"),
        Dict("locale" => "fr", "text" => "bonjour"),
    ]
    @test Opal._localized2str(item, "fr") == "bonjour"
    @test Opal._localized2str(item, "en") == "hello"
    @test Opal._localized2str(item, "de") == ""
end

@testset "Show Opal Object" begin
    opal = Opal.OpalObject(
        name="test",
        url="https://opal-demo.obiba.org",
        username="admin",
        version=parse(VersionNumber, "5.1"),
        rid="session-rid",
        profile="default",
    )
    printed = sprint(show, MIME"text/plain"(), opal)
    @test occursin("url: https://opal-demo.obiba.org", printed)
    @test occursin("name: test", printed)
    @test occursin("version: 5.1", printed)
    @test occursin("username: admin", printed)
    @test occursin("rid: session-rid", printed)
    @test occursin("profile: default", printed)
end
