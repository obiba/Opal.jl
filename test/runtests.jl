using Opal
using Test

include("test_helpers.jl")

@testset "Opal.jl" begin
    # Unit Tests - These run without requiring an Opal server
    @testset "Unit Tests" begin
        @testset "Utils" begin
            include("unit/test_utils.jl")
        end

        @testset "REST Operations" begin
            include("unit/test_rest.jl")
        end

        @testset "Session Management" begin
            include("unit/test_session.jl")
        end

        @testset "Table Operations" begin
            include("unit/test_table.jl")
        end

        @testset "Resource Operations" begin
            include("unit/test_resource.jl")
        end

        @testset "Datasource Operations" begin
            include("unit/test_datasource.jl")
        end

        @testset "Workspace Operations" begin
            include("unit/test_workspace.jl")
        end

        @testset "Symbol Operations" begin
            include("unit/test_symbol.jl")
        end

        @testset "Assignment Operations" begin
            include("unit/test_assign.jl")
        end

        @testset "Command Operations" begin
            include("unit/test_command.jl")
        end

        @testset "Task Operations" begin
            include("unit/test_task.jl")
        end

        @testset "Variables Operations" begin
            include("unit/test_valueset.jl")
        end
    end

    # Integration Tests - These require a live Opal server
    # Set OPAL_TEST_URL environment variable to enable these tests
    if haskey(ENV, "OPAL_TEST_URL")
        @info "Running integration tests against $(get_test_url())"

        @testset "Integration Tests" begin
            @testset "Login/Logout" begin
                include("integration/test_login_logout.jl")
            end

            @testset "Session Management" begin
                include("integration/test_session.jl")
            end

            @testset "Table Operations" begin
                include("integration/test_table.jl")
            end

            @testset "Resource Operations" begin
                include("integration/test_resource.jl")
            end

            @testset "Workspace Operations" begin
                include("integration/test_workspace.jl")
            end

            @testset "Assign/Symbols" begin
                include("integration/test_assign_symbols.jl")
            end

            @testset "Task Operations" begin
                include("integration/test_task.jl")
            end
        end
    else
        @info """
        Skipping integration tests. To run integration tests, set the OPAL_TEST_URL environment variable:

        Example:
            OPAL_TEST_URL="https://opal-demo.obiba.org" julia --project -e 'using Pkg; Pkg.test()'

        Optional environment variables:
            OPAL_TEST_USER="administrator"      (default: administrator)
            OPAL_TEST_PASSWORD="password"       (default: password)
        """
    end
end
