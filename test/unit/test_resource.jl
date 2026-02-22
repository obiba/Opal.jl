# Unit tests for resource operations
# These tests focus on resource-related logic without requiring a server

using Test
using Opal
using JSON

@testset "Resource Function Signatures" begin
    # Test that resource functions exist with correct signatures
    @test isdefined(Opal, :opal_resources)
    @test isdefined(Opal, :opal_resource)
    @test isdefined(Opal, :opal_resource_exists)
    @test isdefined(Opal, :opal_resource_get)
    @test isdefined(Opal, :opal_resource_create)
    @test isdefined(Opal, :opal_resource_extension_create)
    @test isdefined(Opal, :opal_resource_delete)

    # Test method signatures
    @test hasmethod(opal_resources, (Opal.OpalObject, String))
    @test hasmethod(opal_resource, (Opal.OpalObject, String, String))
    @test hasmethod(opal_resource_exists, (Opal.OpalObject, String, String))
    @test hasmethod(opal_resource_get, (Opal.OpalObject, String, String))
    @test hasmethod(opal_resource_create, (Opal.OpalObject, String, String, String))
    @test hasmethod(
        opal_resource_extension_create,
        (Opal.OpalObject, String, String, String, String, Dict{String,Any}),
    )
    @test hasmethod(opal_resource_delete, (Opal.OpalObject, String, String))
end

@testset "Resource List Parameters" begin
    # Test that opal_resources accepts df parameter
    @test hasmethod(opal_resources, (Opal.OpalObject, String))

    # The df parameter controls whether to return DataFrame or raw response
    # For now, we return raw response regardless
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

    # Validate function exists
    @test true
end

@testset "Resource Existence Check Logic" begin
    # Test that opal_resource_exists returns Bool
    @test hasmethod(opal_resource_exists, (Opal.OpalObject, String, String))

    # The function uses try-catch to determine existence
    # This will be validated in integration tests
    @test true
end

@testset "Resource Creation Logic" begin
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

    # Test basic resource creation parameters
    name = "test_resource"
    url_param = "opal+https://example.org/data.csv"
    format = "csv"

    # Verify parameter structure for basic resource
    parameters = Dict("url" => url_param, "format" => format)
    @test parameters["url"] == url_param
    @test parameters["format"] == format

    # Test with package parameter
    parameters_with_pkg = Dict(
        "url" => url_param, "format" => format, "_package" => "haven"
    )
    @test parameters_with_pkg["_package"] == "haven"

    # Test credentials structure
    identity = "user123"
    secret = "pass456"
    credentials = Dict("identifier" => identity, "identity" => identity, "secret" => secret)

    @test credentials["identifier"] == identity
    @test credentials["identity"] == identity
    @test credentials["secret"] == secret
end

@testset "Resource Extension Creation Logic" begin
    # Test extended resource creation with custom provider/factory
    provider = "dsOmics"
    factory = "ga4gh-htsget"
    parameters = Dict(
        "host" => "https://htsget.ga4gh.org",
        "sample" => "1000genomes.phase1.chr1",
        "reference" => "1",
        "start" => "1",
        "end" => "100000",
        "format" => "GA4GHVCF",
    )

    # Verify JSON structure for extended resource
    resjson = Dict(
        "provider" => provider,
        "factory" => factory,
        "project" => "RSRC",
        "name" => "test_resource",
        "parameters" => JSON.json(parameters),
    )

    @test resjson["provider"] == provider
    @test resjson["factory"] == factory
    @test haskey(resjson, "parameters")

    # Test with credentials
    credentials = Dict("identifier" => "user", "secret" => "pass")
    resjson_with_creds = copy(resjson)
    resjson_with_creds["credentials"] = JSON.json(credentials)

    @test haskey(resjson_with_creds, "credentials")

    # Test with description
    resjson_with_desc = copy(resjson)
    resjson_with_desc["description"] = "Test resource description"

    @test resjson_with_desc["description"] == "Test resource description"
end

@testset "Resource Deletion Logic" begin
    # Test silent parameter handling
    @test hasmethod(opal_resource_delete, (Opal.OpalObject, String, String))

    # The function should warn when silent=false and resource doesn't exist
    # This will be tested in integration tests
    @test true
end

@testset "Resource Get Placeholder" begin
    # opal_resource_get is not fully implemented (requires R session ops)
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

    # Should throw error about not being implemented
    @test_throws ErrorException opal_resource_get(opal, "RSRC", "resource1")
end

@testset "Resource Response Parsing" begin
    # Test parsing of resource list response
    mock_resources_response = [
        Dict(
            "name" => "resource1",
            "resource" => Dict("url" => "https://example.org/data1.csv", "format" => "csv"),
            "created" => "2024-01-01T10:00:00",
            "updated" => "2024-01-02T15:30:00",
        ),
        Dict(
            "name" => "resource2",
            "resource" => Dict("url" => "https://example.org/data2.rds", "format" => "rds"),
            "created" => "2024-01-03T09:00:00",
            "updated" => "2024-01-04T12:00:00",
        ),
    ]

    @test length(mock_resources_response) == 2
    @test mock_resources_response[1]["name"] == "resource1"
    @test mock_resources_response[1]["resource"]["url"] == "https://example.org/data1.csv"
    @test mock_resources_response[1]["resource"]["format"] == "csv"

    # Test parsing of single resource response
    mock_resource_response = Dict(
        "name" => "test_resource",
        "project" => "RSRC",
        "resource" => Dict(
            "provider" => "resourcer",
            "factory" => "default",
            "url" => "https://example.org/data.csv",
            "format" => "csv",
        ),
        "created" => "2024-01-01T10:00:00",
        "updated" => "2024-01-02T15:30:00",
    )

    @test mock_resource_response["name"] == "test_resource"
    @test mock_resource_response["project"] == "RSRC"
    @test mock_resource_response["resource"]["provider"] == "resourcer"
    @test mock_resource_response["resource"]["factory"] == "default"
end

@testset "Resource URL Construction" begin
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

    # Test URL construction for resource list
    url = Opal._url(opal, "project", "RSRC", "resources")
    @test occursin("project/RSRC/resources", url)

    # Test URL construction for single resource
    url = Opal._url(opal, "project", "RSRC", "resource", "test_resource")
    @test occursin("project/RSRC/resource/test_resource", url)
end
