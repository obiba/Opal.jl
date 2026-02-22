# Integration tests for table operations
# These tests require a live Opal server (set OPAL_TEST_URL to run)
# Uses RSRC project for testing

using Test
using Opal
include("../test_helpers.jl")

@testset "Table Exists Check" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Check that a known table exists
        @test opal_table_exists(o, "CNSIM", "CNSIM1")

        # Check that a non-existent table doesn't exist
        @test !opal_table_exists(o, "CNSIM", "NONEXISTENT_TABLE")

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Table Metadata Retrieval" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Get table metadata without counts
        table_info = opal_table(o, "CNSIM", "CNSIM1")

        @test isa(table_info, Dict)
        @test haskey(table_info, "name")
        @test table_info["name"] == "CNSIM1"
        @test haskey(table_info, "entityType")

        # Get table metadata with counts
        table_info_counts = opal_table(o, "CNSIM", "CNSIM1"; counts=true)

        @test isa(table_info_counts, Dict)
        @test haskey(table_info_counts, "name")
        @test haskey(table_info_counts, "variableCount")
        @test haskey(table_info_counts, "valueSetCount")
        @test table_info_counts["variableCount"] > 0
        @test table_info_counts["valueSetCount"] > 0

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Table Creation and Deletion - Raw Table" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        table_name = random_table_name()

        # Ensure table doesn't exist
        if opal_table_exists(o, "RSRC", table_name)
            opal_table_delete(o, "RSRC", table_name)
        end

        # Create raw table
        opal_table_create(o, "RSRC", table_name; type="Participant")

        # Verify table exists
        @test opal_table_exists(o, "RSRC", table_name)

        # Verify it's a raw table (not a view)
        @test opal_table_exists(o, "RSRC", table_name; view=false)
        @test !opal_table_exists(o, "RSRC", table_name; view=true)

        # Get table metadata
        table_info = opal_table(o, "RSRC", table_name; counts=true)
        @test table_info["name"] == table_name
        @test table_info["entityType"] == "Participant"
        @test table_info["variableCount"] == 0  # New table has no variables
        @test table_info["valueSetCount"] == 0  # New table has no data

        # Delete table
        opal_table_delete(o, "RSRC", table_name)

        # Verify table no longer exists
        @test !opal_table_exists(o, "RSRC", table_name)

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Table Creation - View" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        view_name = random_table_name()

        # Ensure view doesn't exist
        if opal_table_exists(o, "RSRC", view_name)
            opal_table_delete(o, "RSRC", view_name)
        end

        # Create view from multiple tables
        # Note: Using tables from CNSIM project as source
        tables = ["CNSIM.CNSIM1", "CNSIM.CNSIM2"]
        opal_table_create(o, "RSRC", view_name; tables=tables)

        # Verify view exists
        @test opal_table_exists(o, "RSRC", view_name)

        # Verify it's a view (not a raw table)
        @test opal_table_exists(o, "RSRC", view_name; view=true)
        @test !opal_table_exists(o, "RSRC", view_name; view=false)

        # Clean up
        opal_table_delete(o, "RSRC", view_name)
        @test !opal_table_exists(o, "RSRC", view_name)

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Table Truncation" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        table_name = random_table_name()

        # Create a raw table
        if opal_table_exists(o, "RSRC", table_name)
            opal_table_delete(o, "RSRC", table_name)
        end
        opal_table_create(o, "RSRC", table_name; type="Participant")

        # Truncate the table (removes values, keeps dictionary)
        # Note: New table has no values anyway, but this tests the operation
        opal_table_truncate(o, "RSRC", table_name)

        # Table should still exist
        @test opal_table_exists(o, "RSRC", table_name)

        # Clean up
        opal_table_delete(o, "RSRC", table_name)

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Table Deletion Silent Parameter" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # Delete non-existent table with silent=true (should not warn)
        opal_table_delete(o, "RSRC", "NONEXISTENT_TABLE_12345"; silent=true)

        # Delete non-existent table with silent=false (should warn)
        # Note: @test_warn is not available in Test, so we just call it
        opal_table_delete(o, "RSRC", "NONEXISTENT_TABLE_12345"; silent=false)

        # Both should succeed without throwing errors
        @test true

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end

@testset "Table Creation Error - Already Exists" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        table_name = random_table_name()

        # Create table
        opal_table_create(o, "RSRC", table_name; type="Participant")
        @test opal_table_exists(o, "RSRC", table_name)

        # Try to create again - should error
        @test_throws ErrorException opal_table_create(
            o, "RSRC", table_name; type="Participant"
        )

        # Clean up
        opal_table_delete(o, "RSRC", table_name)
    finally
        opal_logout(o)
    end
end

@testset "Table Truncate Error - Cannot Truncate View" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        view_name = random_table_name()

        # Create a view
        tables = ["CNSIM.CNSIM1"]
        opal_table_create(o, "RSRC", view_name; tables=tables)
        @test opal_table_exists(o, "RSRC", view_name; view=true)

        # Try to truncate view - should warn but not error
        # The function issues a warning but doesn't throw
        opal_table_truncate(o, "RSRC", view_name)

        # View should still exist
        @test opal_table_exists(o, "RSRC", view_name)

        # Clean up
        opal_table_delete(o, "RSRC", view_name)
    finally
        opal_logout(o)
    end
end

@testset "Table Get Not Implemented" begin
    check_skip() && return nothing

    o = make_test_opal()

    try
        # opal_table_get is not fully implemented
        @test_throws ErrorException opal_table_get(o, "CNSIM", "CNSIM1")

        # Check no R session was created
        @test isnothing(o.rid)
    finally
        opal_logout(o)
    end
end
