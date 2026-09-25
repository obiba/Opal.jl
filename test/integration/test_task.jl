# Integration tests for task operations
# Requires a live Opal server (set OPAL_TEST_URL to run)

using Test
using Opal
using DataFrames
include("../test_helpers.jl")

@testset "Task Operations" begin
    check_skip() && return nothing

    o = make_test_opal()

    # list the tasks
    tasks = opal_tasks(o)
    @test isnothing(tasks) || isa(tasks, DataFrame)
    if !isnothing(tasks)
        @test names(tasks) ==
            ["id", "type", "user", "project", "startDate", "endDate", "status"]
    end

    # list the tasks as raw list
    tasks = opal_tasks(o; df=false)
    @test isnothing(tasks) || tasks isa AbstractVector

    opal_logout(o)
end
