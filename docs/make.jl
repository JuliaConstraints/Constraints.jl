using Constraints
using Documenter

makedocs(;
    modules=[Constraints],
    authors="Jean-François Baffier",
    repo="https://github.com/azzaare/Constraints.jl/blob/{commit}{path}#L{line}",
    sitename="Constraints.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://azzaare.github.io/Constraints.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/azzaare/Constraints.jl",
)
