# Opal.jl

[![Docs workflow Status](https://github.com/obiba/Opal.jl/actions/workflows/Docs.yml/badge.svg?branch=main)](https://github.com/obiba/Opal.jl/actions/workflows/Docs.yml?query=branch%3Amain)
[![Test workflow status](https://github.com/obiba/Opal.jl/actions/workflows/Test.yml/badge.svg?branch=main)](https://github.com/obiba/Opal.jl/actions/workflows/Test.yml?query=branch%3Amain)
[![Build Status](https://github.com/obiba/Opal.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/obiba/Opal.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![Aqua QA](https://juliatesting.github.io/Aqua.jl/dev/assets/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

Opal.jl is a Julia client for [Opal](https://www.obiba.org/pages/products/opal/), a data warehouse application for biobanks and epidemiological studies.

## Installation

```julia
using Pkg
Pkg.add("Opal")
```

## Quick Start

```julia
using Opal

# Login to Opal server
opal = opal_login(
    username="administrator",
    password="password",
    url="https://opal-demo.obiba.org"
)

# List available projects
projects = opal_get(opal, "projects")

# Logout when done
opal_logout(opal)
```

## Testing

Opal.jl includes comprehensive unit tests and integration tests.

### Running Unit Tests Only

Unit tests do not require a live Opal server and run automatically in CI:

```bash
# Run all tests (unit tests only without OPAL_TEST_URL)
julia --project -e 'using Pkg; Pkg.test()'

# Or run the test suite directly
julia --project test/runtests.jl
```

### Running Integration Tests

Integration tests require a live Opal server. Set the `OPAL_TEST_URL` environment variable to enable them:

```bash
# Run all tests including integration tests
OPAL_TEST_URL="https://opal-demo.obiba.org" julia --project -e 'using Pkg; Pkg.test()'

# With custom credentials
OPAL_TEST_URL="https://opal-demo.obiba.org" \
OPAL_TEST_USER="administrator" \
OPAL_TEST_PASSWORD="password" \
julia --project -e 'using Pkg; Pkg.test()'
```

### Environment Variables for Testing

- `OPAL_TEST_URL` - Opal server URL (required to run integration tests)
- `OPAL_TEST_USER` - Username for authentication (default: `administrator`)
- `OPAL_TEST_PASSWORD` - Password for authentication (default: `password`)

### Running Individual Test Files

```bash
# Run specific unit test file
julia --project test/unit/test_utils.jl

# Run specific integration test file (requires OPAL_TEST_URL)
OPAL_TEST_URL="https://opal-demo.obiba.org" julia --project test/integration/test_login_logout.jl
```

### Test Organization

The suite is split into `test/unit/` (mocked, no server) and `test/integration/` (live Opal
server). `test/runtests.jl` wires both with SafeTestsets, so every test file runs in an
isolated module; integration test files include the shared helpers from `test/test_helpers.jl`
and skip cleanly when `OPAL_TEST_URL` is unset.

## License

This project is licensed under the MIT license.
