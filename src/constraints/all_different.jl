#!SECTION - all_different

const description_all_different = """
Global constraint ensuring that the values in `x` are all different.
"""

"""
    xcsp_all_different(list::Vector{Int})

Return `true` if all the values of `list` are different, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.

## Variants
- `:all_different`: $description_all_different
```julia
concept(:all_different, x; vals)
concept(:all_different)(x; vals)
```

## Examples
```julia
c = concept(:all_different)

c([1, 2, 3, 4])
c([1, 2, 3, 1])
c([1, 0, 0, 4]; vals=[0])
c([1, 0, 0, 1]; vals=[0])
```
"""
xcsp_all_different(list, ::Nothing) = allunique(list)

function xcsp_all_different(list, except)
    return xcsp_all_different(list = Iterators.filter(x -> x ∉ except[:, 1], list))
end

xcsp_all_different(; list, except = nothing) = xcsp_all_different(list, except)

@usual concept_all_different(x; vals = nothing) = xcsp_all_different(
    list = x, except = vals)

mutable struct AllDifferentInvariant{T, I <: AbstractSet{T}} <: AbstractInvariant
    counts::Dict{T, Int}
    ignored::I
    duplicates::Int
end

supports_incremental(::ConceptError{:all_different}) = true

function _ignored_values(::Type{T}, ::Nothing) where {T}
    return Set{T}()
end

function _ignored_values(::Type{T}, values) where {T}
    ignored = Set{T}()
    for value in values[:, 1]
        push!(ignored, value)
    end
    return ignored
end

function initialize_invariant(
        ::ConceptError{:all_different}, values; X = nothing, vals = nothing)
    T = eltype(values)
    ignored = _ignored_values(T, vals)
    counts = Dict{T, Int}()
    duplicates = 0
    for value in values
        value in ignored && continue
        count = get(counts, value, 0)
        duplicates += !iszero(count)
        counts[value] = count + 1
    end
    return AllDifferentInvariant(counts, ignored, duplicates)
end

invariant_value(invariant::AllDifferentInvariant) = Float64(!iszero(invariant.duplicates))

@inline function _remove_value!(invariant::AllDifferentInvariant, value)
    value in invariant.ignored && return nothing
    count = invariant.counts[value]
    invariant.duplicates -= count > 1
    if count == 1
        delete!(invariant.counts, value)
    else
        invariant.counts[value] = count - 1
    end
    return nothing
end

@inline function _add_value!(invariant::AllDifferentInvariant, value)
    value in invariant.ignored && return nothing
    count = get(invariant.counts, value, 0)
    invariant.duplicates += !iszero(count)
    invariant.counts[value] = count + 1
    return nothing
end

@inline function _apply_change!(invariant::AllDifferentInvariant, change::InvariantChange)
    change.old_value == change.new_value && return nothing
    _remove_value!(invariant, change.old_value)
    _add_value!(invariant, change.new_value)
    return nothing
end

@inline function _revert_change!(invariant::AllDifferentInvariant, change::InvariantChange)
    change.old_value == change.new_value && return nothing
    _remove_value!(invariant, change.new_value)
    _add_value!(invariant, change.old_value)
    return nothing
end

function candidate_value(
        invariant::AllDifferentInvariant, changes::Union{Tuple, AbstractVector})
    foreach(change -> _apply_change!(invariant, change), changes)
    value = invariant_value(invariant)
    foreach(change -> _revert_change!(invariant, change), Iterators.reverse(changes))
    return value
end

function commit_changes!(
        invariant::AllDifferentInvariant, changes::Union{Tuple, AbstractVector})
    foreach(change -> _apply_change!(invariant, change), changes)
    return invariant_value(invariant)
end

function rollback_changes!(
        invariant::AllDifferentInvariant, changes::Union{Tuple, AbstractVector})
    foreach(change -> _revert_change!(invariant, change), Iterators.reverse(changes))
    return invariant_value(invariant)
end

function rebuild_invariant!(invariant::AllDifferentInvariant, values)
    empty!(invariant.counts)
    invariant.duplicates = 0
    for value in values
        _add_value!(invariant, value)
    end
    return invariant_value(invariant)
end

## SECTION - Test Items
@testitem "All Different" tags=[:usual, :constraints, :all_different] begin
    c = USUAL_CONSTRAINTS[:all_different] |> concept
    e = USUAL_CONSTRAINTS[:all_different] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4])
    @test !c([1, 2, 3, 1])
    @test c([1, 0, 0, 4]; vals = [0])
    @test !c([1, 0, 0, 1]; vals = [0])

    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [1, 2, 3, 1])
    @test vs(c, e, [1, 0, 0, 4]; vals = [0])
    @test vs(c, e, [1, 0, 0, 1]; vals = [0])
end

@testitem "Incremental All Different" tags=[:constraints, :all_different, :invariant] begin
    import Test: @inferred, @test

    error = Constraints.make_error(:all_different)
    invariant = initialize_invariant(error, [1, 2, 3, 4])
    duplicate = InvariantChange(4, 4, 2)

    @test @inferred(invariant_value(invariant)) == 0.0
    @test @inferred(candidate_value(invariant, duplicate)) == 1.0
    @test invariant_value(invariant) == 0.0
    @test commit_changes!(invariant, duplicate) == 1.0
    @test rollback_changes!(invariant, duplicate) == 0.0

    swap = (InvariantChange(1, 1, 2), InvariantChange(2, 2, 1))
    @test candidate_value(invariant, swap) == 0.0
    @test invariant_value(invariant) == 0.0

    strings = initialize_invariant(error, ["a", "b", "a"])
    @test invariant_value(strings) == 1.0
    @test candidate_value(strings, InvariantChange(3, "a", "c")) == 0.0

    penalized_error = Constraints.concept_error(
        :all_different, Constraints.concept(:all_different); penalty = 4)
    penalized = initialize_invariant(penalized_error, [1, 2, 3, 4])
    @test supports_incremental(penalized_error)
    @test @inferred(invariant_value(penalized)) == 0.0
    @test @inferred(candidate_value(penalized, duplicate)) == 4.0
    @test commit_changes!(penalized, duplicate) == 4.0
    @test rollback_changes!(penalized, duplicate) == 0.0

    except_zero = initialize_invariant(error, [0, 0, 1]; vals = [0])
    @test invariant_value(except_zero) == 0.0
    @test rebuild_invariant!(except_zero, [1, 1, 0]) == 1.0

    for assignment in Iterators.product(ntuple(_ -> 1:3, 4)...)
        values = collect(assignment)
        trial = initialize_invariant(error, values)
        @test invariant_value(trial) == error(values)
        for position in eachindex(values), replacement in 1:3
            change = InvariantChange(position, values[position], replacement)
            candidate = copy(values)
            candidate[position] = replacement
            @test candidate_value(trial, change) == error(candidate)
            @test invariant_value(trial) == error(values)
        end
        for first in eachindex(values), second in (first + 1):length(values)
            changes = (
                InvariantChange(first, values[first], values[second]),
                InvariantChange(second, values[second], values[first]),
            )
            candidate = copy(values)
            candidate[first], candidate[second] = candidate[second], candidate[first]
            @test candidate_value(trial, changes) == error(candidate)
            @test commit_changes!(trial, changes) == error(candidate)
            @test rollback_changes!(trial, changes) == error(values)
        end
    end
end
