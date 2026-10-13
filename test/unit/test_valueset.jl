# Unit tests for variable and valueset operations
# These tests focus on function signatures and logic without requiring a server

using Test
using Opal
using DataFrames

@testset "Variables Operations Logic" begin
    @test hasmethod(opal_variable, (Opal.OpalObject, String, String, String))
    @test hasmethod(opal_variable_summary, (Opal.OpalObject, String, String, String))
    @test hasmethod(opal_valueset, (Opal.OpalObject, String, String, String))
    @test hasmethod(opal_variables, (Opal.OpalObject, String, String))
end

@testset "Attribute Values" begin
    attributes = [
        Dict("namespace" => nothing, "name" => "status", "value" => "identical"),
        Dict("namespace" => nothing, "name" => "label", "locale" => "en", "value" => "Age"),
        Dict("namespace" => nothing, "name" => "label", "locale" => "fr", "value" => "Âge"),
    ]
    @test opal_attribute_values(attributes) == ["[en] Age", "[fr] Âge"]
    @test length(opal_attribute_values(attributes; name="status")) == 1
    @test isempty(opal_attribute_values(attributes; name="missing"))
    @test isempty(opal_attribute_values([]))
end

@testset "Repeatable Column Logic" begin
    # Opal names the field isRepeatable; absence means false. The old
    # haskey(item, "repeatable") check tested the wrong name and only
    # key existence, not the value.
    items = [
        Dict("name" => "v1", "isRepeatable" => true),
        Dict("name" => "v2", "isRepeatable" => false),
        Dict("name" => "v3"),
    ]
    repeatable = Bool[]
    for item in items
        push!(repeatable, get(item, "isRepeatable", false))
    end
    @test repeatable == [true, false, false]
end
