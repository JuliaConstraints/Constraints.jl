"""
    Constraint
Parametric stucture with the following fields.
- `concept`: a Boolean function that, given an assignment `x`, outputs `true` if `x` satisfies the constraint, and `false` otherwise.
- `error`: a positive function that works as preferences over invalid assignements. Return `0.0` if the constraint is satisfied, and a strictly positive real otherwise.
"""
struct Constraint{FConcept <: Function, FError <: Function}
    concept::FConcept
    error::FError
end

function Constraint()
    return Constraint(_ -> true, _ -> 0.0)
end