using Constraints
using Documenter

makedocs(;
    modules=[Constraints],
    authors="Jean-François Baffier",
    repo="https://github.com/JuliaConstraints/Constraints.jl/blob/{commit}{path}#L{line}",
    sitename="Constraints.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuliaConstraints.github.io/Constraints.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaConstraints/Constraints.jl",
)
