# Integration tests for assignment and symbol operations
# Requires a live Opal server (set OPAL_TEST_URL to run)

using Test
using Opal
using DataFrames: DataFrame
include("../test_helpers.jl")

@testset "Assign and Symbol Operations" begin
    check_skip() && return nothing

    o = make_test_opal()

    # the symbols endpoint returns a JSON scalar when there is a single symbol
    # and a JSON array when there are several
    symbols_list(symbols) = symbols isa AbstractVector ? symbols : [string(symbols)]

    # assign a script and check that the symbol is listed
    opal_assign_script(o, "hello", "function(x) print(paste0('Hello ', x, '!'))")
    symbols = opal_symbols(o)
    @test "hello" in symbols_list(symbols)

    # assign a table with an identifiers column
    opal_assign_table(o, "D", "CNSIM.CNSIM1"; id_name="id")
    symbols = opal_symbols(o)
    @test "D" in symbols_list(symbols)

    # assign dispatches a script assignment
    opal_assign(o, "expr", Expr(:call, :sum, 1, 2))
    symbols = opal_symbols(o)
    @test "expr" in symbols_list(symbols)

    # remove symbols
    opal_rm(o, "hello")
    opal_rm(o, "D")
    opal_rm(o, "expr")
    symbols = opal_symbols(o)
    @test "hello" ∉ symbols_list(symbols)

    opal_logout(o)
end

@testset "Variables Repeatable Column" begin
    check_skip() && return nothing

    o = make_test_opal()
    symbol_name = "rep_df_$(rand(1000:9999))"

    try
        # import a small table with a repeatable variable (CNSIM1 has
        # multiple rows per entity id): opal_variables must return a real
        # Bool repeatable column (bug #9: it used to be all false)
        opal_assign_table_tibble(o, symbol_name, "CNSIM.CNSIM1"; id_name="id")
        opal_symbol_import(o, symbol_name, "RSRC"; wait=true)

        variables = opal_variables(o, "RSRC", symbol_name)
        @test variables isa DataFrame
        @test hasproperty(variables, :repeatable)
        @test eltype(variables.repeatable) == Bool

        # clean up the imported table
        opal_table_delete(o, "RSRC", symbol_name; silent=true)
    catch
        # if the import failed, still try to clean up
        opal_table_delete(o, "RSRC", symbol_name; silent=true)
        rethrow()
    finally
        opal_rm(o, symbol_name)
        opal_logout(o)
    end
end
