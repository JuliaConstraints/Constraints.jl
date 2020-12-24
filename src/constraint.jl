"""
    Constraint
Parametric stucture with the following fields.
- `concept`: a Boolean function that, given an assignment `x`, outputs `true` if `x` satisfies the constraint, and `false` otherwise.
- `error`: a positive function that works as preferences over invalid assignements. Return `0.0` if the constraint is satisfied, and a strictly positive real otherwise.
"""
struct Constraint{FConcept <: Function, FError <: Function}
    _args_length::Union{Nothing, Int}
    _concept::FConcept
    _error::FError
    _params_length::Union{Nothing, Int}

    function Constraint(;
        args_length = nothing,
        concept = (x...) -> true,
        error = (x...) -> Float64(!concept(x...)),
        param = 0,
    )
        new{typeof(concept), typeof(error)}(args_length, concept, error, param)
    end
end

concept(c::Constraint) = c._concept
concept(c::Constraint, x...) = concept(c)(x...)
# concept(c::Constraint, x...; param...) = concept(c)(x...; param = param)

error_f(c::Constraint) = c._error
error_f(c::Constraint, x...) = error_f(c)(x...)
# error_f(c::Constraint, x...; param...) = error_f(c)(x...; param = param)

args_length(c::Constraint) = c._args_length

params_length(c::Constraint) = c._params_length
