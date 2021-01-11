module Constraints

# Imports
import Dictionaries: Dictionary, set!

# Exports
export Constraint, usual_constraints
export args_length, concept, error_f, params_length, symmetries

# Includes internals
include("utils.jl")
include("constraint.jl")

# Includes constraints
include("constraints/all_different.jl")
include("constraints/dist_different.jl")
include("constraints/equals.jl")
include("constraints/ordered.jl")

"""
    usual_constraints::Dict
Dictionary that contains all the usual constraints defined in Constraint.jl. 
"""
const usual_constraints = Dict(
    :all_different => _all_different,
    :all_equal => _all_equal,
    :all_equal_param => _all_equal_param,
    :always_true => Constraint(),
    :dist_different => _dist_different,
    :eq => _eq,
    :ordered => _ordered,
)

end
