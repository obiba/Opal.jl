"""
Test helper functions for Opal.jl tests.

This module provides utility functions for both unit and integration tests,
including test skipping, test data generation, and mock Opal connections.
"""

using Test
using Opal
using JSON

"""
    check_skip() -> Bool

Check if integration tests should be skipped based on environment variables.
Returns true if tests should be skipped, false otherwise.

Integration tests are skipped when OPAL_TEST_URL is not set.
"""
function check_skip()
    if !haskey(ENV, "OPAL_TEST_URL")
        return true
    end
    return false
end

"""
    get_test_url() -> String

Get the Opal server URL for testing from environment variable.
Defaults to "https://opal-demo.obiba.org" if not set.
"""
function get_test_url()
    get(ENV, "OPAL_TEST_URL", "https://opal-demo.obiba.org")
end

"""
    get_test_credentials() -> Tuple{String, String}

Get test credentials (username, password) from environment variables.
Defaults to ("administrator", "password") if not set.
"""
function get_test_credentials()
    username = get(ENV, "OPAL_TEST_USER", "administrator")
    password = get(ENV, "OPAL_TEST_PASSWORD", "password")
    return (username, password)
end

"""
    make_test_opal() -> OpalObject

Create an Opal connection for integration testing.
Uses credentials and URL from environment variables or defaults.
"""
function make_test_opal()
    username, password = get_test_credentials()
    url = get_test_url()
    return opal_login(; username=username, password=password, url=url)
end

"""
    make_test_dataset() -> Dict

Create a simple test dataset (Dict-based) for basic tests.
Returns a dictionary with arrays for id, mpg, cyl, disp, hp, and name.

This is a simplified equivalent of R's mtcars dataset.
"""
function make_test_dataset()
    Dict(
        "id" => collect(1:10),
        "mpg" => [21.0, 21.0, 22.8, 21.4, 18.7, 18.1, 14.3, 24.4, 22.8, 19.2],
        "cyl" => [6, 6, 4, 6, 8, 6, 8, 4, 4, 6],
        "disp" => [160.0, 160.0, 108.0, 258.0, 360.0, 225.0, 360.0, 146.7, 140.8, 167.6],
        "hp" => [110, 110, 93, 110, 175, 105, 245, 62, 95, 123],
        "name" => [
            "Mazda RX4",
            "Mazda RX4 Wag",
            "Datsun 710",
            "Hornet 4 Drive",
            "Hornet Sportabout",
            "Valiant",
            "Duster 360",
            "Merc 240D",
            "Merc 230",
            "Merc 280",
        ],
    )
end

"""
    make_test_dataset_with_repeatables() -> Dict

Create a test dataset with repeatable entries (multiple rows per ID).
Used for testing repeatable variable handling.
"""
function make_test_dataset_with_repeatables()
    Dict(
        "id" => [1, 2, 3, 1, 1, 2, 2, 3, 3, 4],
        "id2" => [1, 2, 3, 4, 5, 6, 7, 8, 9, missing],
        "sex" => [missing, "M", "F", "M", "M", missing, "F", "F", "M", missing],
        "var1" => [7.3, 1.0, missing, 2.3, 1.4, missing, 2.4, 5.4, -99.0, missing],
    )
end

"""
    mock_response(status::Int, body::String; headers::Dict=Dict()) -> Dict

Create a mock HTTP response for unit testing.

# Arguments
- `status::Int`: HTTP status code
- `body::String`: Response body (usually JSON)
- `headers::Dict`: Optional HTTP headers (default: {"content-type" => "application/json"})
"""
function mock_response(
    status::Int, body::String; headers::Dict{String,String}=Dict{String,String}()
)
    default_headers = Dict("content-type" => "application/json")
    merged_headers = merge(default_headers, headers)
    return Dict("status" => status, "headers" => merged_headers, "body" => body)
end

"""
    mock_json_response(status::Int, data::Dict) -> Dict

Create a mock HTTP response with JSON data for unit testing.

# Arguments
- `status::Int`: HTTP status code
- `data::Dict`: Dictionary that will be converted to JSON
"""
function mock_json_response(status::Int, data::Dict)
    body = JSON.json(data)
    return mock_response(status, body)
end

"""
    random_table_name() -> String

Generate a random table name for testing to avoid conflicts.
"""
function random_table_name()
    return "test_table_$(rand(1000:9999))"
end

"""
    random_resource_name() -> String

Generate a random resource name for testing to avoid conflicts.
"""
function random_resource_name()
    return "test_resource_$(rand(1000:9999))"
end
