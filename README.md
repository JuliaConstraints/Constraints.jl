# Constraints

[![Docs](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaConstraints.github.io/Constraints.jl/dev)
[![Docs](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaConstraints.github.io/Constraints.jl/stable)
[![Build Status](https://github.com/JuliaConstraints/Constraints.jl/workflows/CI/badge.svg)](https://github.com/JuliaConstraints/Constraints.jl/actions)
[![codecov](https://codecov.io/gh/JuliaConstraints/Constraints.jl/branch/main/graph/badge.svg?token=dyNBGiwnY1)](https://codecov.io/gh/JuliaConstraints/Constraints.jl)
[![Code Style: Blue](https://img.shields.io/badge/code%20style-blue-4495d1.svg)](https://github.com/invenia/BlueStyle)

# Constraints.jl

A back-end package for JuliaConstraints front packages, such as `LocalSearchSolvers.jl`.

It provides the following features:
- A dictionary to store usual constraint: `usual_constraint`, which contains the following entries (in alphabetical order):
  - :`all_different`
  - :`all_equal`
  - :`at_least`
  - :`at_most`
  - :`cardinality`
  - :`cardinality_closed`
  - :`cardinality_open`
  - :`channel`
  - :`circuit`
  - :`conflicts`
  - :`count`
  - :`cumulative`
  - :`decreasing`
  - :`dist_different`
  - :`element`
  - :`exactly`
  - :`extension`
  - :`increasing`
  - :`instantiation`
  - :`maximum`
  - :`mdd`
  - :`minimum`
  - :`no_overlap`
  - :`no_overlap_no_zero`
  - :`no_overlap_with_zero`
  - :`nvalues`
  - :`ordered`
  - :`regular`
  - :`strictly_decreasing`
  - :`strictly_increasing`
  - :`sum`
  - :`supports`

- For each constraint `c`, the following properties
  - arguments length
  - concept (predicate the variables compliance with `c`)
  - error (a function that evaluate how much `c` is violated)
  - parameters length
  - known symmetries of `c`
- A learning function using `CompositionalNetworks.jl`. If no error function is given when instantiating `c`, it will check the existence of a composition related to `c` and set the error to it.

## Contributing

Contributions to this package are more than welcome and can be arbitrarily, and not exhaustively, split as follows:
- Adding new constraints and symmetries
- Adding new ICNs to learn error of existing constraints
- Creating other compositional networks which target other kind of constraints
- Just making stuff better, faster, user-friendlier, etc.

### Contact
Do not hesitate to contact me (@azzaare) or other members of JuliaConstraints on GitHub (file an issue), the julialang discourse forum, the julialang slack channel, the julialang zulip server, or the Human of Julia (HoJ) discord server.
