"""
    Constraint
Parametric stucture with the following fields.
- `concept`: a Boolean function that, given an assignment `x`, outputs `true` if `x` satisfies the constraint, and `false` otherwise.
- `error`: a positive function that works as preferences over invalid assignements. Return `0.0` if the constraint is satisfied, and a strictly positive real otherwise.
"""
struct Constraint{FConcept <: Function, FError <: Function}
    _concept::FConcept
    _error::FError

    function Constraint(;
        concept = (x...) -> true,
        error = (x...) -> Float64(!concept(x...)),
    )
        new{typeof(concept), typeof(error)}(concept, error)
    end
end

concept(c::Constraint) = c._concept
concept(c::Constraint, x...) = concept(c)(x...)

error_f(c::Constraint) = c._error
error_f(c::Constraint, x...) = error_f(c)(x...)