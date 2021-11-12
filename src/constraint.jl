"""
    symmetries
A Dictionary that contains the function to apply for each symmetry to avoid searching a whole space.
"""
const usual_symmetries = Dict(:permutable => sort)

"""
    Constraint
Parametric stucture with the following fields.
- `concept`: a Boolean function that, given an assignment `x`, outputs `true` if `x` satisfies the constraint, and `false` otherwise.
- `error`: a positive function that works as preferences over invalid assignements. Return `0.0` if the constraint is satisfied, and a strictly positive real otherwise.
"""
mutable struct Constraint{FConcept<:Function,FError<:Function}
    args::Int
    concept::FConcept
    description::String
    error::FError
    params_length::Int
    symmetries::Set{Symbol}

    function Constraint(;
        args=0,
        concept=x -> true,
        description="No given description!",
        error=(x; param=0, dom_size=0) -> Float64(!concept(x)),
        param=0,
        syms=Set{Symbol}(),
    )
        return new{typeof(concept),typeof(error)}(
            args, concept, description, error, param, syms
        )
    end
end

"""
    concept(c::Constraint)
Return the concept (function) of constraint `c`.
    concept(c::Constraint, x...; param = nothing)
Apply the concept of `c` to values `x` and optionally `param`.
"""
concept(c::Constraint) = c.concept
function concept(c::Constraint, x; param=nothing)
    return isnothing(param) ? concept(c)(x) : concept(c)(x; param)
end

"""
    error_f(c::Constraint)
Return the error function of constraint `c`.
    error_f(c::Constraint, x; param = nothing)
Apply the error function of `c` to values `x` and optionally `param`.
"""
error_f(c::Constraint) = c.error
function error_f(c::Constraint, x; param=nothing, dom_size=0)
    return isnothing(param) ? error_f(c)(x; dom_size) : error_f(c)(x; param, dom_size)
end

"""
    args(c::Constraint)
Return the expected length restriction of the arguments in a constraint `c`. The value `nothing` indicates that any strictly positive number of value is accepted.
"""
args(c::Constraint) = c.args

"""
    params_length(c::Constraint)
Return the expected length restriction of the arguments in a constraint `c`. The value `nothing` indicates that any strictly positive number of parameters is accepted.
"""
params_length(c::Constraint) = c.params_length

"""
    symmetries(c::Constraint)
Return the list of symmetries of `c`.
"""
symmetries(c::Constraint) = c.symmetries

function make_error(symb::Symbol)
    return begin
        if isdefined(Constraints, Symbol("icn_$symb"))
            eval(Symbol("icn_$symb"))
        elseif isdefined(Constraints, Symbol("error_$symb"))
            eval(Symbol("error_$symb"))
        else
            ((x; param=nothing, dom_size=0) -> Float64(!eval(Symbol("concept_$symb"))(x)))
        end
    end
end

macro usual(name::Symbol, param_args_syms...)
    start_syms = 1

    param = if 1 ≤ length(param_args_syms) && isa(param_args_syms[1], Int)
        start_syms = 2
        param_args_syms[1]
    else
        0
    end

    args = if length(param_args_syms) ≥ 2 && isa(param_args_syms[2], Int)
        start_syms = 3
        param_args_syms[2]
    else
        0
    end

    syms = Set{Symbol}(param_args_syms[start_syms:end])
    concept = eval(:concept * name)
    error = make_error(name)
    ds = :description * name

    description = isdefined(Constraints, ds) ? eval(ds) : "No given description!"

    push!(
        usual_constraints,
        name => Constraint(; args, concept, description, error, param, syms),
    )
    return nothing
end
