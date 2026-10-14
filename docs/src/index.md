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

Unit tests run without a live server; integration tests require one via the `OPAL_TEST_URL`
environment variable (optional `OPAL_TEST_USER` and `OPAL_TEST_PASSWORD`):

```bash
# All tests (unit only without OPAL_TEST_URL)
julia --project -e 'using Pkg; Pkg.test()'

# Integration tests against a live Opal server
OPAL_TEST_URL="https://opal-demo.obiba.org" julia --project -e 'using Pkg; Pkg.test()'
```

See the [API Reference](api.md) for the full list of exported functions.

## License

This project is licensed under the GPL-3.0 license.
