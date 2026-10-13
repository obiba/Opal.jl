# Unit tests for task operations
# These tests focus on function signatures without requiring a server

using Test
using Opal

@testset "Task Operations Logic" begin
    @test hasmethod(opal_tasks, (Opal.OpalObject,))
    @test hasmethod(opal_task, (Opal.OpalObject, String))
    @test hasmethod(opal_task_cancel, (Opal.OpalObject, String))
    @test hasmethod(opal_task_wait, (Opal.OpalObject, String))
end

@testset "Task Wait Keyword Regression" begin
    # the kwarg is maxtime; the old name `max` shadowed Base.max and made
    # max(1, round(waited / 10)) throw on the first loop
    src = read(joinpath(dirname(@__DIR__), "..", "src", "opal_task.jl"), String)
    @test occursin("maxtime::Union{Nothing,Int}=nothing", src)
    @test !occursin("; max::Union{Nothing,Int}", src)
    @test !occursin(", max::Union{Nothing,Int}", src)
    @test occursin("waited <= maxtime", src)
end
