# Opal.jl

[![Build Status](https://github.com/obiba/Opal.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/obiba/Opal.jl/actions/workflows/CI.yml?query=branch%3Amain)

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

```bash
test/
├── runtests.jl           # Main test runner
├── test_helpers.jl       # Shared test helper functions
├── unit/                 # Unit tests (no server required)
│   ├── test_utils.jl     # Utility function tests
│   ├── test_rest.jl      # REST operation tests
│   ├── test_session.jl   # Session management tests
│   ├── test_table.jl     # Table operation tests
│   └── test_resource.jl  # Resource operation tests
└── integration/          # Integration tests (live server required)
    ├── test_login_logout.jl
    ├── test_session.jl
    ├── test_table.jl
    └── test_resource.jl
```

## Development

For development guidelines, code style, and workflow instructions, see [AGENTS.md](AGENTS.md).

## License

This project is licensed under the GPL-3.0 license.
