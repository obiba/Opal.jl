using Documenter
using Documenter: Remotes

using Opal

makedocs(;
    modules=[Opal],
    authors="Hugo Solleder <hugo.solleder@epfl.ch> and contributors",
    repo=Remotes.GitHub("obiba", "Opal.jl"),
    sitename="Opal.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://obiba.github.io/Opal.jl",
        assets=String[],
    ),
    warnonly=[:missing_docs],
    pages=["Home" => "index.md", "API Reference" => "api.md"],
)

deploydocs(; repo="github.com/obiba/Opal.jl", devbranch="main")
