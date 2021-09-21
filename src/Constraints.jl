module Constraints

# Imports
using CompositionalNetworks
using ConstraintDomains
using DataFrames
using Dictionaries
using PrettyTables

# Exports
export Constraint
export concept, error_f
export args_length, params_length
export symmetries
export usual_constraints, usual_symmetries
export learn_from_icn

# Includes internals
include("utils.jl")
include("constraint.jl")

# Includes learned errors from ICN
foreach(include, readdir(joinpath(dirname(pathof(Constraints)), "compositions"); join=true))

## NOTE - Includes constraints
include("usual_constraints.jl")

# NOTE - Generic Constraints: intension, extension
include("constraints/intention.jl")
include("constraints/extension.jl")

# NOTE - Constraints defined from Languages
include("constraints/regular.jl")
include("constraints/mdd.jl")

# NOTE - Comparison-based Constraints
include("constraints/all_different.jl")
include("constraints/all_equal.jl")
include("constraints/ordered.jl")

# NOTE - Counting and Summing Constraints
include("constraints/sum.jl")
include("constraints/count.jl")
include("constraints/n_values.jl")
include("constraints/cardinality.jl")

# NOTE - Connection Constraints
include("constraints/maximum.jl")
include("constraints/minimum.jl")
include("constraints/element.jl")
include("constraints/channel.jl")

# NOTE - Packing and Scheduling Constraints
include("constraints/cumulative.jl")
include("constraints/no_overlap.jl")

# NOTE - Constraints on Graphs
include("constraints/circuit.jl")

# NOTE - Elementary Constraints
include("constraints/instantiation.jl")

# TODO - where?
include("constraints/sequential_tasks.jl")
include("constraints/equals.jl")
include("constraints/less.jl")

# include learn script
include("learn.jl")

end
