# Constraints

[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaConstraints.github.io/Constraints.jl/dev)
[![Build Status](https://github.com/JuliaConstraints/Constraints.jl/workflows/CI/badge.svg)](https://github.com/JuliaConstraints/Constraints.jl/actions)
[![codecov](https://codecov.io/gh/JuliaConstraints/Constraints.jl/branch/main/graph/badge.svg?token=dyNBGiwnY1)](https://codecov.io/gh/JuliaConstraints/Constraints.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

# Constraints.jl

A  back-end pacage for JuliaConstraints front packages, such as `LocalSearchSolvers.jl`.

It provides the following features:
- A dictionary to store usual constraint: `usual_contraint`, which contains the following entries
  - `:all_different`
  - `:dist_different`
  - `:eq`, `:all_equal`, `:all_equal_param`
  - `:ordered`
  - `:always_true` (mainly for testing default `Constraint()` constructor)
- For each constraint `c`, the following properties
  - arguments length
  - concept (predicate the variables compliance with `c`)
  - error (a function that evaluate how much `c` is violated)
  - parameters length
  - known symmetries of `c`
- A learning function using `CompositionalNetworks.jl`. If no error function is given when instanciating `c`, it will check the existence of a composition related to `c` and set the error to it.

## Contributing

Contributions to this package are more than welcome and can be arbitrarily, and not exhaustively, split as follows:
- Adding new constraints and symmetries
- Adding new ICNs to learn error of existing constraints
- Creating other compositional networks which target other kind of constraints
- Just making stuff better, faster, user-friendlier, etc.

### Contact
Do not hesitate to contact me (@azzaare) or other members of JuliaConstraints on GitHub (file an issue), the julialang discourse forum, the julialang slack channel, the julialang zulip server, or the Human of Julia (HoJ) discord server.
