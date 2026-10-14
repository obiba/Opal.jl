using SafeTestsets
using Test

@testset "Opal.jl" begin
    # Unit Tests - These run without requiring an Opal server
    @testset "Unit Tests" begin
        @safetestset "Utils" begin
            include("unit/test_utils.jl")
        end

        @safetestset "REST Operations" begin
            include("unit/test_rest.jl")
        end

        @safetestset "Session Management" begin
            include("unit/test_session.jl")
        end

        @safetestset "Table Operations" begin
            include("unit/test_table.jl")
        end

        @safetestset "Resource Operations" begin
            include("unit/test_resource.jl")
        end

        @safetestset "Datasource Operations" begin
            include("unit/test_datasource.jl")
        end

        @safetestset "Workspace Operations" begin
            include("unit/test_workspace.jl")
        end

        @safetestset "Symbol Operations" begin
            include("unit/test_symbol.jl")
        end

        @safetestset "Assignment Operations" begin
            include("unit/test_assign.jl")
        end

        @safetestset "Command Operations" begin
            include("unit/test_command.jl")
        end

        @safetestset "Task Operations" begin
            include("unit/test_task.jl")
        end

        @safetestset "Variables Operations" begin
            include("unit/test_valueset.jl")
        end
    end

    # Integration Tests - These require a live Opal server
    # Set OPAL_TEST_URL environment variable to enable these tests
    if haskey(ENV, "OPAL_TEST_URL")
        @info "Running integration tests against $(ENV["OPAL_TEST_URL"])"

        @testset "Integration Tests" begin
            @safetestset "Login/Logout" begin
                include("integration/test_login_logout.jl")
            end

            @safetestset "Session Management" begin
                include("integration/test_session.jl")
            end

            @safetestset "Table Operations" begin
                include("integration/test_table.jl")
            end

            @safetestset "Resource Operations" begin
                include("integration/test_resource.jl")
            end

            @safetestset "Workspace Operations" begin
                include("integration/test_workspace.jl")
            end

            @safetestset "Assign/Symbols" begin
                include("integration/test_assign_symbols.jl")
            end

            @safetestset "Task Operations" begin
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
