"""
    symmetries
A Dictionary that contains the function to apply for each symmetry to avoid searching a whole space.
"""
const usual_symmetries = Dict(
    :permutable => sort,
)

"""
    Constraint
Parametric stucture with the following fields.
- `concept`: a Boolean function that, given an assignment `x`, outputs `true` if `x` satisfies the constraint, and `false` otherwise.
- `error`: a positive function that works as preferences over invalid assignements. Return `0.0` if the constraint is satisfied, and a strictly positive real otherwise.
"""
mutable struct Constraint{FConcept <: Function,FError <: Function}
    _args_length::Union{Nothing,Int}
    _concept::FConcept
    _error::FError
    _params_length::Union{Nothing,Int}
    _symmetries::Set{Symbol}

    function Constraint(;
        args_length=nothing,
        concept=x -> true,
        error=x -> Float64(!concept(x)),
        param=0,
        syms=Set{Symbol}(),
    )   
        new{typeof(concept),typeof(error)}(args_length, concept, error, param, syms)
    end
end

"""
    concept(c::Constraint)
Return the concept (function) of constraint `c`.
    concept(c::Constraint, x...; param = nothing)
Apply the concept of `c` to values `x` and optionally `param`.
"""
concept(c::Constraint) = c._concept
function concept(c::Constraint, x; param=nothing)
    return isnothing(param) ? concept(c)(x) : concept(c)(x, param=param)
end

"""
    error_f(c::Constraint)
Return the error function of constraint `c`.
    error_f(c::Constraint, x; param = nothing)
Apply the error function of `c` to values `x` and optionally `param`.
"""
error_f(c::Constraint) = c._error
function error_f(c::Constraint, x; param=nothing)
    return isnothing(param) ? error_f(c)(x) : error_f(c)(x, param=param)
end

"""
    args_length(c::Constraint)
Return the expected length restriction of the arguments in a constraint `c`. The value `nothing` indicates that any strictly positive number of value is accepted.
"""
args_length(c::Constraint) = c._args_length

"""
    params_length(c::Constraint)
Return the expected length restriction of the arguments in a constraint `c`. The value `nothing` indicates that any strictly positive number of parameters is accepted.
"""
params_length(c::Constraint) = c._params_length

"""
    symmetries(c::Constraint)
Return the list of symmetries of `c`.
"""
symmetries(c::Constraint) = c._symmetries

function _make_error(symb::Symbol)
    path = "../learn/compositions/_icn_$(symb).jl"
    expr = ispath(path) ? Symbol("_icn_$symb") : Symbol("_error_$symb")
    @info expr
    return eval(expr)
end