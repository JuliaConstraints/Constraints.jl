using Constraints
using CompositionalNetworks
using ConstraintDomains
using Documenter

makedocs(;
    modules=[Constraints, ConstraintDomains, CompositionalNetworks],
    authors="Jean-François Baffier",
    repo="https://github.com/JuliaConstraints/Constraints.jl/blob/{commit}{path}#L{line}",
    sitename="Constraints.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", nothing) == "true",
        canonical="https://JuliaConstraints.github.io/Constraints.jl",
        assets = ["assets/favicon.ico"; "assets/github_buttons.js"; "assets/custom.css"],
    ),
    pages=[
        "Home" => "index.md",
        "Learning (ICN)" => "learning.md",
        "Dependencies" => [
            "ConstraintDomains.jl" => "domain.md",
            "CompositionalNetworks.jl" => "icn.md",
        ],
        "Library" => [
            "Public" => "public.md",
            "Internal" => "internal.md"
        ],
    ],
)

deploydocs(;
    repo="github.com/JuliaConstraints/Constraints.jl.git",
    devbranch="main",
)
