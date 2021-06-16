module Constraints

# Imports
using Dictionaries: include
using CompositionalNetworks: include
using Dictionaries
using CompositionalNetworks
using ConstraintDomains

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
foreach(include, readdir(joinpath(dirname(pathof(Constraints)),"compositions"), join = true))

# Includes constraints
include("constraints/all_different.jl")
include("constraints/dist_different.jl")
include("constraints/equals.jl")
include("constraints/less.jl")
include("constraints/ordered.jl")
include("constraints/sequential_tasks.jl")

"""
    usual_constraints::Dict
Dictionary that contains all the usual constraints defined in Constraint.jl.
"""
const usual_constraints = Dict(
    :all_different => all_different,
    :all_equal => all_equal,
    :all_equal_param => all_equal_param,
    :always_true => Constraint(),
    :dist_different => dist_different,
    :eq => eq,
    :less_than_param => less_than_param,
    :minus_equal_param => minus_equal_param,
    :ordered => ordered,
    :sequential_tasks => sequential_tasks,
    :sum_equal_param => sum_equal_param,
)

# include learn script
include("learn.jl")

end
