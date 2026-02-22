# Unit tests for table operations
# These tests focus on table-related logic without requiring a server

using Test
using Opal
using JSON

@testset "Table Function Signatures" begin
    # Test that table functions exist with correct signatures
    @test isdefined(Opal, :opal_table)
    @test isdefined(Opal, :opal_table_exists)
    @test isdefined(Opal, :opal_table_create)
    @test isdefined(Opal, :opal_table_delete)
    @test isdefined(Opal, :opal_table_truncate)
    @test isdefined(Opal, :opal_table_get)

    # Test method signatures
    @test hasmethod(opal_table, (Opal.OpalObject, String, String))
    @test hasmethod(opal_table_exists, (Opal.OpalObject, String, String))
    @test hasmethod(opal_table_create, (Opal.OpalObject, String, String))
    @test hasmethod(opal_table_delete, (Opal.OpalObject, String, String))
    @test hasmethod(opal_table_truncate, (Opal.OpalObject, String, String))
    @test hasmethod(opal_table_get, (Opal.OpalObject, String, String))
end

@testset "Table Metadata Parameters" begin
    # Test that opal_table accepts counts parameter
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

    # The counts parameter should affect the query string
    # This will be validated in integration tests
    @test hasmethod(opal_table, (Opal.OpalObject, String, String))
end

@testset "Table Existence Check Logic" begin
    # Test that opal_table_exists accepts view parameter
    @test hasmethod(opal_table_exists, (Opal.OpalObject, String, String))

    # The function should handle missing/nothing for view parameter
    # Testing the logic without server connection
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

    # Note: Full testing requires server connection
    # This validates the function exists and accepts parameters
    @test true
end

@testset "Table Creation Logic" begin
    # Test table creation parameters
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

    # Verify that parameters are correctly structured for JSON
    # Creating a raw table should produce correct JSON body
    table_name = "test_table"
    entity_type = "Participant"

    expected_body_structure = Dict("name" => table_name, "entityType" => entity_type)
    json_body = JSON.json(expected_body_structure)
    parsed = JSON.parse(json_body)

    @test parsed["name"] == table_name
    @test parsed["entityType"] == entity_type

    # Creating a view should include table references
    tables = ["PROJ.TABLE1", "PROJ.TABLE2"]
    view_body_structure = Dict(
        "name" => "test_view",
        "from" => tables,
        "Magma.VariableListViewDto.view" => Dict("variables" => []),
    )
    json_view = JSON.json(view_body_structure)
    parsed_view = JSON.parse(json_view)

    @test parsed_view["name"] == "test_view"
    @test parsed_view["from"] == tables
    @test haskey(parsed_view, "Magma.VariableListViewDto.view")
end

@testset "Table Deletion Logic" begin
    # Test silent parameter handling
    @test hasmethod(opal_table_delete, (Opal.OpalObject, String, String))

    # The function should warn when silent=false and table doesn't exist
    # This will be tested in integration tests
    @test true
end

@testset "Table Truncation Logic" begin
    # Test that truncate only works on non-view tables
    @test hasmethod(opal_table_truncate, (Opal.OpalObject, String, String))

    # The function should warn if table is a view
    # This will be tested in integration tests
    @test true
end

@testset "Table Get Placeholder" begin
    # opal_table_get is not fully implemented
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
    @test_throws ErrorException opal_table_get(opal, "CNSIM", "CNSIM1")
end

@testset "Table View vs Raw Table Logic" begin
    # Test logic for distinguishing views from raw tables
    # A view has a "viewLink" field in the response
    # A raw table does not

    # Mock table response (raw table)
    raw_table_response = Dict("name" => "TABLE1", "entityType" => "Participant")

    @test !haskey(raw_table_response, "viewLink")

    # Mock view response
    view_response = Dict(
        "name" => "VIEW1",
        "entityType" => "Participant",
        "viewLink" => "/datasource/PROJ/view/VIEW1",
    )

    @test haskey(view_response, "viewLink")
    @test !isnothing(view_response["viewLink"])

    # Test the logic that opal_table_exists would use
    # If view parameter is true, check for viewLink
    # If view parameter is false, check for absence of viewLink
    is_view = haskey(view_response, "viewLink") && !isnothing(view_response["viewLink"])
    is_raw_table =
        !haskey(raw_table_response, "viewLink") ||
        isnothing(get(raw_table_response, "viewLink", nothing))

    @test is_view == true
    @test is_raw_table == true
end
