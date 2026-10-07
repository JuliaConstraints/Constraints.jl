"""
    USUAL_SYMMETRIES
A Dictionary that contains the function to apply for each symmetry to avoid searching a whole space.
"""
const USUAL_SYMMETRIES = Dict(:permutable => sort)

"""
    Constraint
Parametric structure with the following fields.
- `concept`: a Boolean function that, given an assignment `x`, outputs `true` if `x` satisfies the constraint, and `false` otherwise.
- `error`: a positive function that works as preferences over invalid assignments. Return `0.0` if the constraint is satisfied, and a strictly positive real otherwise.
"""
mutable struct Constraint{FConcept <: Function, FError <: Function}
    args::Int
    concept::FConcept
    description::String
    error::FError
    params::Vector{Dict{Symbol, Bool}}
    symmetries::Set{Symbol}

    function Constraint(;
            args = 0,
            concept = x -> true,
            description = "No given description!",
            error = (x; param = 0, dom_size = 0) -> Float64(!concept(x)),
            params = Vector{Dict{Symbol, Bool}}(),
            syms = Set{Symbol}()
    )
        return new{typeof(concept), typeof(error)}(
            args,
            concept,
            description,
            error,
            params,
            syms
        )
    end
end

struct ConceptError{S, F <: Function} <: Function
    concept::F
end

function (error::ConceptError)(x; X = nothing, dom_size = nothing, params...)
    return Float64(!error.concept(x; params...))
end

ConceptError(symb::Symbol, concept::F) where {F <: Function} =
    ConceptError{symb, F}(concept)

"""A Boolean concept mapped to zero when satisfied and a fixed positive penalty otherwise."""
struct ConceptPenalty{S, F <: Function, P <: Real} <: Function
    concept::F
    penalty::P

    function ConceptPenalty{S}(concept::F, penalty::P) where {S, F <: Function, P <: Real}
        value = Float64(penalty)
        isfinite(value) && value > 0 || throw(ArgumentError(
            "a concept penalty must be finite and strictly positive"))
        return new{S, F, P}(concept, penalty)
    end
end

function (error::ConceptPenalty)(x; X = nothing, dom_size = nothing, params...)
    return error.concept(x; params...) ? 0.0 : Float64(error.penalty)
end

function ConceptPenalty(symb::Symbol, concept::F, penalty::P) where {
        F <: Function, P <: Real}
    ConceptPenalty{symb}(concept, penalty)
end

"""
    concept_error([symb], concept; penalty = 1.0)

Build an exact cost from a Boolean concept. A unit penalty returns `ConceptError`; any other
finite positive constant returns `ConceptPenalty`. The symbolic identity is carried by the
concrete type so registered constraints may attach incremental invariants.
"""
function concept_error(symb::Symbol, concept::F; penalty::Real = 1.0) where {F <: Function}
    return isone(penalty) ? ConceptError(symb, concept) :
           ConceptPenalty(symb, concept, penalty)
end

function concept_error(concept::F; penalty::Real = 1.0) where {F <: Function}
    return concept_error(:anonymous, concept; penalty)
end

"""
    concept(c::Constraint)
Return the concept (function) of constraint `c`.
    concept(c::Constraint, x...; param = nothing)
Apply the concept of `c` to values `x` and optionally `param`.
"""
concept(c::Constraint) = c.concept
function concept(c::Constraint, x; param = nothing)
    return isnothing(param) ? concept(c)(x) : concept(c)(x; param)
end

"""
    error_f(c::Constraint)
Return the error function of constraint `c`.
    error_f(c::Constraint, x; param = nothing)
Apply the error function of `c` to values `x` and optionally `param`.
"""
error_f(c::Constraint) = c.error
function error_f(c::Constraint, x; param = nothing, dom_size = 0)
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

"""
    make_error(symb::Symbol, [concept]; prefer_concept = false, fallback_penalty = 1.0)

Create a function that returns an error based on the predicate of the constraint identified by the symbol provided.

## Arguments
- `symb::Symbol`: The symbol used to determine the error function to be returned. The function first checks if a predicate with the prefix "icn_" exists in the Constraints module. If it does, it returns that function. If it doesn't, it checks for a predicate with the prefix "error_". If that exists, it returns that function. If neither exists, it returns a function that evaluates the predicate with the prefix "concept_" and returns the negation of its result cast to Float64.
- `prefer_concept`: Bypass registered learned and handcrafted errors to execute the Boolean
  concept cost explicitly.
- `fallback_penalty`: Strictly positive finite cost used when the Boolean concept is false.

## Returns
- Function: A function that takes in a variable `x` and an arbitrary number of parameters `params`. The function returns a Float64.

# Examples
```julia
e = make_error(:all_different)
e([1, 2, 3]) # Returns 0.0
e([1, 1, 3]) # Returns 1.0
```
"""
function make_error(symb::Symbol, concept_f::Union{Nothing, Function} = nothing;
        prefer_concept::Bool = false, fallback_penalty::Real = 1.0)
    icn_symb = Symbol("icn_$symb")
    !prefer_concept && isdefined(Constraints, icn_symb) &&
        return getfield(Constraints, icn_symb)

    error_symb = Symbol("error_$symb")
    !prefer_concept && isdefined(Constraints, error_symb) &&
        return getfield(Constraints, error_symb)

    if isnothing(concept_f)
        concept_symb = Symbol("concept_$symb")
        isdefined(Constraints, concept_symb) ||
            throw(ArgumentError("No concept or error function is defined for constraint :$symb"))
        concept_f = getfield(Constraints, concept_symb)
    end
    return concept_error(symb, concept_f; penalty = fallback_penalty)
end

"""
    shrink_concept(s)

Simply delete the `concept_` part of symbol or string starting with it. TODO: add a check with a warning if `s` starts with something different.
"""
shrink_concept(s) = Symbol(string(s)[9:end])

"""
    concept_vs_error(c, e, args...; kargs...)

Compare the results of a concept function and an error function for the same inputs. It is mainly used for testing purposes.

# Arguments
- `c`: The concept function.
- `e`: The error function.
- `args...`: Positional arguments to be passed to both the concept and error functions.
- `kargs...`: Keyword arguments to be passed to both the concept and error functions.

# Returns
- Boolean: Returns true if the result of the concept function is not equal to whether the result of the error function is greater than 0.0. Otherwise, it returns false.

# Examples
```julia
concept_vs_error(all_different, make_error(:all_different), [1, 2, 3]) # Returns false
```
"""
function concept_vs_error(c, e, args...; kargs...)
    return c(args...; kargs...) ≠ (e(args...; kargs...) > 0.0)
end
@testitem "Empty constraint" tags=[:constraint, :empty] begin
    c = Constraint()
    @test concept(c, []) == true
    @test error_f(c, []) == 0.0
end


@testitem "Concept errors resolve their function once" tags=[:constraint, :error] begin
    import Test: @inferred, @test, @test_throws

    error = Constraints.make_error(:all_different)
    @test error isa Constraints.ConceptError
    @test @inferred(error([1, 2, 3])) == 0.0
    @test @inferred(error([1, 1, 3])) == 1.0
    @test fieldtype(typeof(error), :concept) !== Any
    penalized = Constraints.concept_error(
        :all_different, Constraints.concept(:all_different); penalty = 4)
    @test penalized isa Constraints.ConceptPenalty{:all_different}
    @test @inferred(penalized([1, 2, 3])) == 0.0
    @test @inferred(penalized([1, 1, 3])) == 4.0
    @test Constraints.make_error(
        :all_different; prefer_concept = true, fallback_penalty = 7)([1, 1]) == 7.0
    @test_throws ArgumentError Constraints.concept_error(identity; penalty = 0)
    @test_throws ArgumentError Constraints.concept_error(identity; penalty = Inf)
    @test_throws ArgumentError Constraints.make_error(:not_a_constraint)
end
