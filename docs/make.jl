using Constraints
using Documenter

makedocs(;
    modules=[Constraints],
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
        "Library" => "library.md",
        "Contributing" => "contributing.md",
    ],
)

deploydocs(;
    repo="github.com/JuliaConstraints/Constraints.jl.git",
    devbranch="main",
)
