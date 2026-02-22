# Integration tests for resource operations
# These tests require a live Opal server (set OPAL_TEST_URL to run)
# Uses RSRC project for testing

using Test
using Opal
include("../test_helpers.jl")

@testset "Resource List" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Get list of resources in RSRC project
        resources = opal_resources(o, "RSRC")

        @test isa(resources, Union{Vector,Dict})

        # If there are resources, check structure
        if isa(resources, Vector) && length(resources) > 0
            first_resource = resources[1]
            @test haskey(first_resource, "name")
        end

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Resource Existence Check" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Check for a resource that doesn't exist
        @test !opal_resource_exists(o, "RSRC", "NONEXISTENT_RESOURCE_12345")

        # Note: We can't guarantee any specific resource exists
        # but we can test the function works
        @test true

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Resource Creation and Deletion - Basic" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        resource_name = random_resource_name()

        # Ensure resource doesn't exist
        if opal_resource_exists(o, "RSRC", resource_name)
            opal_resource_delete(o, "RSRC", resource_name)
        end

        # Create a basic resource
        url = "opal+https://opal-demo.obiba.org/ws/files/test.csv"
        opal_resource_create(
            o, "RSRC", resource_name, url; format="csv", description="Test resource"
        )

        # Verify resource exists
        @test opal_resource_exists(o, "RSRC", resource_name)

        # Get resource details
        resource_info = opal_resource(o, "RSRC", resource_name)

        @test isa(resource_info, Dict)
        @test haskey(resource_info, "name")
        @test resource_info["name"] == resource_name

        # Delete resource
        opal_resource_delete(o, "RSRC", resource_name)

        # Verify resource no longer exists
        @test !opal_resource_exists(o, "RSRC", resource_name)

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Resource Creation with Credentials" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        resource_name = random_resource_name()

        # Ensure resource doesn't exist
        if opal_resource_exists(o, "RSRC", resource_name)
            opal_resource_delete(o, "RSRC", resource_name)
        end

        # Create resource with credentials
        url = "opal+https://opal-demo.obiba.org/ws/files/protected.csv"
        opal_resource_create(
            o,
            "RSRC",
            resource_name,
            url;
            format="csv",
            identity="testuser",
            secret="testpass",
            description="Test resource with credentials",
        )

        # Verify resource exists
        @test opal_resource_exists(o, "RSRC", resource_name)

        # Get resource details
        resource_info = opal_resource(o, "RSRC", resource_name)
        @test resource_info["name"] == resource_name

        # Clean up
        opal_resource_delete(o, "RSRC", resource_name)
        @test !opal_resource_exists(o, "RSRC", resource_name)

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Resource Extension Creation" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        resource_name = random_resource_name()

        # Ensure resource doesn't exist
        if opal_resource_exists(o, "RSRC", resource_name)
            opal_resource_delete(o, "RSRC", resource_name)
        end

        # Create extended resource with custom provider and factory
        parameters = Dict("url" => "https://example.org/data.csv", "format" => "csv")

        opal_resource_extension_create(
            o,
            "RSRC",
            resource_name,
            "resourcer",
            "default",
            parameters;
            description="Extended test resource",
        )

        # Verify resource exists
        @test opal_resource_exists(o, "RSRC", resource_name)

        # Get resource details
        resource_info = opal_resource(o, "RSRC", resource_name)
        @test resource_info["name"] == resource_name

        # Clean up
        opal_resource_delete(o, "RSRC", resource_name)
        @test !opal_resource_exists(o, "RSRC", resource_name)

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Resource Deletion Silent Parameter" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Delete non-existent resource with silent=true (should not warn)
        opal_resource_delete(o, "RSRC", "NONEXISTENT_RESOURCE_12345"; silent=true)

        # Delete non-existent resource with silent=false (should warn)
        opal_resource_delete(o, "RSRC", "NONEXISTENT_RESOURCE_12345"; silent=false)

        # Both should succeed without throwing errors
        @test true

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Resource Creation Error - Already Exists" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        resource_name = random_resource_name()

        # Create resource
        url = "opal+https://opal-demo.obiba.org/ws/files/test.csv"
        opal_resource_create(o, "RSRC", resource_name, url; format="csv")
        @test opal_resource_exists(o, "RSRC", resource_name)

        # Try to create again - should warn but not error
        # (opal_resource_extension_create warns instead of throwing)
        opal_resource_create(o, "RSRC", resource_name, url; format="csv")

        # Resource should still exist
        @test opal_resource_exists(o, "RSRC", resource_name)

        # Clean up
        opal_resource_delete(o, "RSRC", resource_name)
    finally
        opal_logout(o)
    end
end

@testset "Resource Get Not Implemented" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        resource_name = random_resource_name()

        # Create a resource first
        url = "opal+https://opal-demo.obiba.org/ws/files/test.csv"
        opal_resource_create(o, "RSRC", resource_name, url; format="csv")
        @test opal_resource_exists(o, "RSRC", resource_name)

        # opal_resource_get is not fully implemented (requires R session ops)
        @test_throws ErrorException opal_resource_get(o, "RSRC", resource_name)

        # Check no R session was created
        @test isnothing(o.rid)

        # Clean up
        opal_resource_delete(o, "RSRC", resource_name)
    finally
        opal_logout(o)
    end
end

@testset "Multiple Resources Creation and Cleanup" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Create multiple resources
        resource_names = [random_resource_name() for _ in 1:3]

        for name in resource_names
            url = "opal+https://opal-demo.obiba.org/ws/files/$(name).csv"
            opal_resource_create(o, "RSRC", name, url; format="csv")
            @test opal_resource_exists(o, "RSRC", name)
        end

        # Get resource list - should include our new resources
        resources = opal_resources(o, "RSRC")
        @test isa(resources, Union{Vector,Dict})

        # Clean up all created resources
        for name in resource_names
            opal_resource_delete(o, "RSRC", name)
            @test !opal_resource_exists(o, "RSRC", name)
        end

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end
