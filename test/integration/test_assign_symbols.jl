# Integration tests for assignment and symbol operations
# Requires a live Opal server (set OPAL_TEST_URL to run)

using Test
using Opal
using DataFrames: DataFrame

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
