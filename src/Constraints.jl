module Constraints

# Imports
import Dictionaries: Dictionary, set!

# Exports
export Constraint, usual_constraints
export concept, error_f

# Includes internals
include("utils.jl")
include("constraint.jl")

# Includes constraints
include("constraints/all_different.jl")

# Dict with all the constraint in the package
const usual_constraints = Dict(
    :alway_true => Constraint(),
    :all_different => _all_different,
)

end
