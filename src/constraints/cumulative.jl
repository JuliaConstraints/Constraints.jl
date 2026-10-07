const description_cumulative = """
Global constraint operating on a set of tasks, defined by `origin` (starting times), `length`, and `height`. This constraint ensures that, at each point in time, the sum of the `height` of tasks that overlap that point, respects a numerical condition.
"""

"""
    xcsp_cumulative(; origins, lengths, heights, condition)

Return `true` if the cumulative constraint is satisfied, `false` otherwise. The cumulative constraint is a global constraint operating on a set of tasks, defined by `origin` (starting times), `length`, and `height`. This constraint ensures that, at each point in time, the sum of the `height` of tasks that overlap that point, respects a numerical condition.

## Arguments
- `origins::AbstractVector`: list of origins of the tasks.
- `lengths::AbstractVector`: list of lengths of the tasks.
- `heights::AbstractVector`: list of heights of the tasks.
- `condition::Tuple`: condition to check.

## Variants
- `:cumulative`: $description_cumulative
```julia
concept(:cumulative, x; pair_vars, op, val)
concept(:cumulative)(x; pair_vars, op, val)
```

## Examples
```julia
c = concept(:cumulative)

c([1, 2, 3, 4, 5]; val = 1)
c([1, 2, 2, 4, 5]; val = 1)
c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = ≤, val = 5)
c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = <, val = 5)
```
"""
function xcsp_cumulative(; origins, lengths, heights, condition)
    length(origins) == length(lengths) == length(heights) || throw(
        DimensionMismatch("cumulative origins, lengths and heights must have the same length"))
    time_type = promote_type(eltype(origins), eltype(lengths))
    load_type = promote_type(eltype(heights), Int)
    # Outside all tasks (including the empty task list), the load is zero.
    condition[1](zero(load_type), condition[2]) || return false
    events = Vector{Tuple{time_type, load_type}}(undef, 2length(origins))
    @inbounds for task in eachindex(origins)
        event = 2task - 1
        start = convert(time_type, origins[task])
        height = convert(load_type, heights[task])
        events[event] = (start, height)
        events[event + 1] = (start + lengths[task], -height)
    end
    sort!(events; alg = Base.Sort.QuickSort)

    usage = zero(load_type)
    event = firstindex(events)
    @inbounds while event <= lastindex(events)
        time = events[event][1]
        while event <= lastindex(events) && events[event][1] == time
            usage += events[event][2]
            event += 1
        end
        condition[1](usage, condition[2]) || return false
    end
    return true
end

function concept_cumulative(x, pair_vars, op, val)
    return xcsp_cumulative(
        origins = x,
        lengths = pair_vars[1, :],
        heights = pair_vars[2, :],
        condition = (op, val)
    )
end

function concept_cumulative(x, pair_vars::AbstractVector{T}, op, val) where {T <: Number}
    length(pair_vars) == length(x) ||
        throw(DimensionMismatch("cumulative task data and origins must have the same length"))
    return xcsp_cumulative(
        origins = x,
        lengths = pair_vars,
        heights = pair_vars,
        condition = (op, val)
    )
end

@usual function concept_cumulative(
        x;
        pair_vars = ones(eltype(x), (2, length(x))),
        op = ≤,
        val
)
    return concept_cumulative(x, pair_vars, op, val)
end

"""Stateful cumulative evaluator with a constraint-owned reusable event buffer."""
mutable struct CumulativeInvariant{
    O <: AbstractVector,
    L <: AbstractVector,
    H <: AbstractVector,
    F,
    V,
    E <: AbstractVector
} <: AbstractInvariant
    origins::O
    lengths::L
    heights::H
    operator::F
    target::V
    events::E
    current::Float64
end

supports_incremental(::ConceptError{:cumulative}) = true

function _functional_cumulative(error, values, X, parameters)
    fallback = concept_error(:cumulative_functional, error.concept)
    return initialize_invariant(fallback, values; X, parameters...)
end

function _cumulative_parameters(pair_vars, values)
    T = eltype(values)
    isconcretetype(T) && T <: Real || return nothing
    lengths = Vector{T}(undef, length(values))
    heights = Vector{T}(undef, length(values))
    try
        if pair_vars isa AbstractMatrix
            size(pair_vars) == (2, length(values)) || return nothing
            copyto!(lengths, @view(pair_vars[1, :]))
            copyto!(heights, @view(pair_vars[2, :]))
        elseif pair_vars isa AbstractVector
            length(pair_vars) == length(values) || return nothing
            copyto!(lengths, pair_vars)
            copyto!(heights, pair_vars)
        else
            return nothing
        end
        all(length -> length >= zero(T), lengths) || return nothing
        all(height -> height >= zero(T), heights) || return nothing
    catch error
        error isa InexactError || error isa MethodError || error isa TypeError || rethrow()
        return nothing
    end
    return lengths, heights
end

function _cumulative_value!(invariant::CumulativeInvariant)
    origins = invariant.origins
    lengths = invariant.lengths
    heights = invariant.heights
    events = invariant.events
    @inbounds for index in eachindex(origins)
        event_index = 2index - 1
        height = heights[index]
        events[event_index] = (origins[index], height)
        events[event_index + 1] = (origins[index] + lengths[index], -height)
    end
    sort!(events; alg = Base.Sort.QuickSort)
    usage = zero(eltype(heights))
    event = firstindex(events)
    @inbounds while event <= lastindex(events)
        time = events[event][1]
        while event <= lastindex(events) && events[event][1] == time
            usage += events[event][2]
            event += 1
        end
        invariant.operator(usage, invariant.target) || return 1.0
    end
    return 0.0
end

function initialize_invariant(error::ConceptError{:cumulative}, values;
        X = nothing,
        pair_vars = ones(eltype(values), (2, length(values))),
        op = ≤,
        val
)
    parameters = (; pair_vars, op, val)
    cumulative_parameters = _cumulative_parameters(pair_vars, values)
    cumulative_parameters === nothing &&
        return _functional_cumulative(error, values, X, parameters)
    lengths, heights = cumulative_parameters
    origins = collect(values)
    T = eltype(origins)
    events = Vector{Tuple{T, T}}(undef, 2length(origins))
    invariant = CumulativeInvariant(
        origins, lengths, heights, op, val, events, 0.0)
    invariant.current = _cumulative_value!(invariant)
    return invariant
end

invariant_value(invariant::CumulativeInvariant) = invariant.current

@inline function _apply_cumulative_origins!(invariant::CumulativeInvariant, changes)
    @inbounds for change in changes
        invariant.origins[change.position] = change.new_value
    end
    return nothing
end

@inline function _revert_cumulative_origins!(invariant::CumulativeInvariant, changes)
    @inbounds for change in Iterators.reverse(changes)
        invariant.origins[change.position] = change.old_value
    end
    return nothing
end

function candidate_value(
        invariant::CumulativeInvariant, changes::Union{Tuple, AbstractVector})
    isempty(changes) && return invariant_value(invariant)
    _apply_cumulative_origins!(invariant, changes)
    try
        return _cumulative_value!(invariant)
    finally
        _revert_cumulative_origins!(invariant, changes)
    end
end

function commit_changes!(
        invariant::CumulativeInvariant, changes::Union{Tuple, AbstractVector})
    isempty(changes) && return invariant_value(invariant)
    _apply_cumulative_origins!(invariant, changes)
    invariant.current = _cumulative_value!(invariant)
    return invariant.current
end

function rollback_changes!(
        invariant::CumulativeInvariant, changes::Union{Tuple, AbstractVector})
    isempty(changes) && return invariant_value(invariant)
    _revert_cumulative_origins!(invariant, changes)
    invariant.current = _cumulative_value!(invariant)
    return invariant.current
end

function rebuild_invariant!(invariant::CumulativeInvariant, values)
    length(values) == length(invariant.origins) ||
        throw(DimensionMismatch("cumulative origins and task data must have the same length"))
    copyto!(invariant.origins, values)
    invariant.current = _cumulative_value!(invariant)
    return invariant.current
end

@testitem "Cumulative" tags=[:usual, :constraints, :cumulative] begin
    c = USUAL_CONSTRAINTS[:cumulative] |> concept
    e = USUAL_CONSTRAINTS[:cumulative] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; val = 1)
    @test !c([1, 2, 2, 4, 5]; val = 1)
    @test c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = ≤, val = 5)
    @test !c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = <, val = 5)
    not_in = (load, forbidden) -> load ∉ forbidden
    @test c([0, 0]; pair_vars = [1 1; 1 1], op = not_in, val = 1:1)

    @test vs(c, e, [1, 2, 3, 4, 5]; val = 1)
    @test vs(c, e, [1, 2, 2, 4, 5]; val = 1)
    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = ≤, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = <, val = 5)
    @test vs(c, e, [0, 2, 4]; pair_vars = [2, 2, 2], op = <=, val = 2)
end

@testitem "Incremental cumulative" tags=[:constraints, :cumulative, :invariant] begin
    import Test: @inferred, @test

    task_data = [2 1 2 1; 2 1 2 1]
    bound = bind_error(
        Constraints.make_error(:cumulative); pair_vars = task_data, op = <=, val = 3)

    for assignment in Iterators.product(ntuple(_ -> 0:3, 4)...)
        origins = collect(assignment)
        invariant = initialize_invariant(bound, origins)
        @test supports_incremental(invariant)
        @test @inferred(invariant_value(invariant)) == bound(origins)
        for position in eachindex(origins), replacement in 0:3

            change = InvariantChange(position, origins[position], replacement)
            candidate = copy(origins)
            candidate[position] = replacement
            @test candidate_value(invariant, change) == bound(candidate)
            @test invariant_value(invariant) == bound(origins)
        end
        changes = (
            InvariantChange(1, origins[1], origins[3]),
            InvariantChange(3, origins[3], origins[1])
        )
        candidate = copy(origins)
        candidate[1], candidate[3] = candidate[3], candidate[1]
        @test candidate_value(invariant, changes) == bound(candidate)
        @test commit_changes!(invariant, changes) == bound(candidate)
        @test rollback_changes!(invariant, changes) == bound(origins)
    end

    strict = bind_error(
        Constraints.make_error(:cumulative); pair_vars = task_data, op = <, val = 4)
    strict_invariant = initialize_invariant(strict, [0, 1, 2, 3])
    @test invariant_value(strict_invariant) == strict([0, 1, 2, 3])
    @test rebuild_invariant!(strict_invariant, [0, 0, 0, 0]) == strict([0, 0, 0, 0])

    not_in = (load, forbidden) -> load ∉ forbidden
    simultaneous = bind_error(Constraints.make_error(:cumulative);
        pair_vars = [1 1; 1 1], op = not_in, val = 1:1)
    simultaneous_invariant = initialize_invariant(simultaneous, [0, 0])
    @test invariant_value(simultaneous_invariant) == simultaneous([0, 0]) == 0.0

    vector_data = bind_error(
        Constraints.make_error(:cumulative); pair_vars = [1, 1, 1, 1], op = <=, val = 2)
    vector_invariant = initialize_invariant(vector_data, [0, 1, 2, 3])
    @test supports_incremental(vector_invariant)
    @test invariant_value(vector_invariant) == vector_data([0, 1, 2, 3])

    atypical = bind_error(Constraints.make_error(:cumulative);
        pair_vars = [-1 1 1 1; 1 1 1 1], op = <=, val = 2)
    fallback = initialize_invariant(atypical, [0, 1, 2, 3])
    @test !supports_incremental(fallback)
    @test invariant_value(fallback) == atypical([0, 1, 2, 3])
end
