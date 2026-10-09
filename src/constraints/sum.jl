const description_sum = """
Global constraint ensuring that the sum of the variables in `x` satisfies a given numerical condition.
"""

"""
    xcsp_sum(list, coeffs, condition)

Return `true` if the sum of the variables in `list` satisfies the given condition, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `coeffs::Vector{Int}`: list of coefficients to use.
- `condition`: condition to satisfy.

## Variants
- `:sum`: $description_sum
```julia
concept(:sum, x; op===, pair_vars=ones(x), val)
concept(:sum)(x; op===, pair_vars=ones(x), val)
```

## Examples
```julia
c = concept(:sum)

c([1, 2, 3, 4, 5]; op===, val=15)
c([1, 2, 3, 4, 5]; op===, val=2)
c([1, 2, 3, 4, 3]; op=≤, val=15)
c([1, 2, 3, 4, 3]; op=≤, val=3)
```
"""
xcsp_sum(; list, coeffs, condition) = condition[1](sum(coeffs .* list), condition[2])

struct _SumDefaultCoefficients end
const _SumNativeInteger = Union{Bool, Int8, Int16, Int32, Int64, Int128,
    UInt8, UInt16, UInt32, UInt64, UInt128}

_sum_default_coefficients(x) = ones(eltype(x), length(x))
_sum_default_coefficients(::Vector{T}) where {T<:_SumNativeInteger} =
    _SumDefaultCoefficients()

@usual function concept_sum(x; op = ==, pair_vars = _sum_default_coefficients(x), val)
    # Primitive integer multiplication by one preserves each value and its
    # type. Sum the same vector with Base's original reduction and widening.
    pair_vars isa _SumDefaultCoefficients && return op(sum(x), val)
    return xcsp_sum(list = x, coeffs = pair_vars, condition = (op, val))
end

mutable struct SumInvariant{C <: AbstractVector, S, F, V} <: AbstractInvariant
    coefficients::C
    total::S
    operator::F
    target::V
end

supports_incremental(::ConceptError{:sum}) = true

function initialize_invariant(
        ::ConceptError{:sum}, values;
        X = nothing,
        op = ==,
        pair_vars = ones(eltype(values), length(values)),
        val
)
    coefficients = collect(pair_vars)
    length(coefficients) == length(values) ||
        throw(DimensionMismatch("sum coefficients and values must have the same length"))
    total = mapreduce(*, +, coefficients, values)
    return SumInvariant(coefficients, total, op, val)
end

invariant_value(invariant::SumInvariant) =
    Float64(!invariant.operator(invariant.total, invariant.target))

@inline function _sum_delta(invariant::SumInvariant, changes::Union{Tuple, AbstractVector})
    delta = zero(invariant.total)
    @inbounds for change in changes
        delta += invariant.coefficients[change.position] *
                 (change.new_value - change.old_value)
    end
    return delta
end

function candidate_value(invariant::SumInvariant, changes::Union{Tuple, AbstractVector})
    total = invariant.total + _sum_delta(invariant, changes)
    return Float64(!invariant.operator(total, invariant.target))
end

function commit_changes!(invariant::SumInvariant, changes::Union{Tuple, AbstractVector})
    invariant.total += _sum_delta(invariant, changes)
    return invariant_value(invariant)
end

function rollback_changes!(invariant::SumInvariant, changes::Union{Tuple, AbstractVector})
    invariant.total -= _sum_delta(invariant, changes)
    return invariant_value(invariant)
end

function rebuild_invariant!(invariant::SumInvariant, values)
    length(invariant.coefficients) == length(values) ||
        throw(DimensionMismatch("sum coefficients and values must have the same length"))
    invariant.total = mapreduce(*, +, invariant.coefficients, values)
    return invariant_value(invariant)
end

@testitem "sum" tags=[:usual, :constraints, :sum] begin
    c = USUAL_CONSTRAINTS[:sum] |> concept
    e = USUAL_CONSTRAINTS[:sum] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 15)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 2)
    @test c([1, 2, 3, 4, 3]; op = <=, val = 15)
    @test !c([1, 2, 3, 4, 3]; op = <=, val = 3)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 15)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 2)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 15)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 3)
end

@testitem "Incremental Sum" tags=[:constraints, :sum, :invariant] begin
    import Test: @inferred, @test, @test_throws

    error = bind_error(Constraints.make_error(:sum); op = ==, pair_vars = [2, 3, 4], val = 20)
    invariant = initialize_invariant(error, [1, 2, 3])
    change = InvariantChange(1, 1, 2)

    @test @inferred(invariant_value(invariant)) == 0.0
    @test @inferred(candidate_value(invariant, change)) == 1.0
    @test invariant_value(invariant) == 0.0
    @test commit_changes!(invariant, change) == 1.0
    @test rollback_changes!(invariant, change) == 0.0

    penalized_error = Constraints.concept_error(
        :sum, Constraints.concept(:sum); penalty = 5)
    penalized = initialize_invariant(
        bind_error(penalized_error; op = ==, pair_vars = [2, 3, 4], val = 20),
        [1, 2, 3],
    )
    @test supports_incremental(penalized_error)
    @test @inferred(invariant_value(penalized)) == 0.0
    @test @inferred(candidate_value(penalized, change)) == 5.0

    batch = (InvariantChange(1, 1, 2), InvariantChange(2, 2, 1))
    @test candidate_value(invariant, batch) == 1.0
    @test rebuild_invariant!(invariant, [2, 0, 4]) == 0.0
    @test_throws DimensionMismatch initialize_invariant(
        bind_error(Constraints.make_error(:sum); op = ==, pair_vars = [1], val = 1),
        [1, 2],
    )

    coefficients = [2, -1, 3, 4]
    bound = bind_error(
        Constraints.make_error(:sum); op = <=, pair_vars = coefficients, val = 8)
    for assignment in Iterators.product(ntuple(_ -> -1:2, 4)...)
        values = collect(assignment)
        trial = initialize_invariant(bound, values)
        @test invariant_value(trial) == bound(values)
        for position in eachindex(values), replacement in -1:2
            candidate_change = InvariantChange(position, values[position], replacement)
            candidate = copy(values)
            candidate[position] = replacement
            @test candidate_value(trial, candidate_change) == bound(candidate)
            @test invariant_value(trial) == bound(values)
        end
        changes = (
            InvariantChange(1, values[1], values[3]),
            InvariantChange(3, values[3], values[1]),
        )
        candidate = copy(values)
        candidate[1], candidate[3] = candidate[3], candidate[1]
        @test candidate_value(trial, changes) == bound(candidate)
        @test commit_changes!(trial, changes) == bound(candidate)
        @test rollback_changes!(trial, changes) == bound(values)
    end
end
