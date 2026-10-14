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

@testset "Task Id Round-Trip (location parsing + wait)" begin
    check_skip() && return nothing

    o = make_test_opal()
    symbol_name = "import_df_$(rand(1000:9999))"

    try
        # assign a small tibble and import it: the import creates a task
        # whose id is extracted from the Location header
        opal_assign_table_tibble(o, symbol_name, "CNSIM.CNSIM1")
        task = opal_symbol_import(o, symbol_name, "RSRC"; wait=false)

        # the returned task id must be the real id (last path segment of
        # /ws/shell/command/<id>), not a truncated one
        @test !isnothing(task)
        @test task isa String
        @test !isempty(task)

        # the task must be findable by its id
        command = opal_task(o, task)
        @test isa(command, Dict)
        @test get(command, "id", "") == task
        @test haskey(command, "status")

        # opal_task_wait must complete without throwing (the import is
        # small and fast; the wait loop exercises maxtime handling)
        opal_task_wait(o, task; maxtime=120)
        command = opal_task(o, task)
        @test get(command, "status", "") == "SUCCEEDED"
    finally
        opal_rm(o, symbol_name)
        # remove the imported table (named after the symbol in RSRC)
        opal_table_delete(o, "RSRC", symbol_name; silent=true)
        opal_logout(o)
    end
end
