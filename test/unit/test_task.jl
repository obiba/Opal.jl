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
