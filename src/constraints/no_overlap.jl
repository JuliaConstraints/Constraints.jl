const description_no_overlap = """
Global constraint operating on a set of tasks, defined by `origin` (starting times), and `length`. This constraint ensures that tasks do not overlap in time, i.e., for any two tasks, either the first task finishes before the second task starts, or the second task finishes before the first task starts. Often used in scheduling problems.
"""

const description_no_overlap_no_zero = """
Global constraint operating on a set of tasks, defined by `origin` (starting times), and `length`. This constraint ensures that tasks do not overlap in time, i.e., for any two tasks, either the first task finishes before the second task starts, or the second task finishes before the first task starts. This variant ignores zero-length tasks. Often used in scheduling problems.
"""

const description_no_overlap_with_zero = """
Global constraint operating on a set of tasks, defined by `origin` (starting times), and `length`. This constraint ensures that tasks do not overlap in time, i.e., for any two tasks, either the first task finishes before the second task starts, or the second task finishes before the first task starts. This variant includes zero-length tasks. Often used in scheduling problems.
"""

"""
    xcsp_no_overlap(; origins, lengths, zero_ignored)

Return `true` if the no_overlap constraint is satisfied, `false` otherwise. The no_overlap constraint is a global constraint used in constraint programming, often in scheduling problems. It ensures that tasks do not overlap in time, i.e., for any two tasks, either the first task finishes before the second task starts, or the second task finishes before the first task starts.

## Arguments
- `origins::AbstractVector`: list of origins of the tasks.
- `lengths::AbstractVector`: list of lengths of the tasks.
- `zero_ignored::Bool`: whether to ignore zero-length tasks.

## Variants
- `:no_overlap`: $description_no_overlap
```julia
concept(:no_overlap, x; pair_vars, bool)
concept(:no_overlap)(x; pair_vars, bool)
```
- `:no_overlap_no_zero`: $description_no_overlap_no_zero
```julia
concept(:no_overlap_no_zero, x; pair_vars)
concept(:no_overlap_no_zero)(x; pair_vars)
```
- `:no_overlap_with_zero`: $description_no_overlap_with_zero
```julia
concept(:no_overlap_with_zero, x; pair_vars)
concept(:no_overlap_with_zero)(x; pair_vars)
```

## Examples
```julia
c = concept(:no_overlap)

c([1, 2, 3, 4, 5])
c([1, 2, 3, 4, 1])
c([1, 2, 4, 6, 3]; pair_vars = [1, 1, 1, 1, 1])
c([1, 2, 4, 6, 3]; pair_vars = [1, 1, 1, 3, 1])
c([1, 2, 4, 6, 3]; pair_vars = [1, 1, 3, 1, 1])
c([1, 1, 1, 3, 5, 2, 7, 7, 5, 12, 8, 7]; pair_vars = [2, 4, 1, 4 ,2 ,3, 5, 1, 2, 3, 3, 2], dim = 3)
c([1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4]; pair_vars = [2, 4, 1, 4 ,2 ,3, 5, 1, 2, 3, 3, 2], dim = 3)
```
"""
function xcsp_no_overlap(origins, lengths, zero_ignored)
    length(origins) == length(lengths) || throw(DimensionMismatch(
        "origins and lengths must contain the same number of tasks"))
    previous = (-Inf, -1)
    for t in sort(collect(zip(origins, lengths)))
        zero_ignored && iszero(t[2]) && continue
        sum(previous) ≤ t[1] || return false
        previous = t
    end
    return true
end

function xcsp_no_overlap(
        origins::AbstractVector{NTuple{K, T}},
        lengths::AbstractVector{NTuple{K, T}},
        zero_ignored
) where {K, T <: Number}
    length(origins) == length(lengths) ||
        throw(DimensionMismatch("origins and lengths must contain the same number of boxes"))
    for first_index in firstindex(origins):(lastindex(origins) - 1)
        first_length = lengths[first_index]
        for second_index in (first_index + 1):lastindex(origins)
            second_length = lengths[second_index]
            zero_ignored &&
                (any(iszero, first_length) || any(iszero, second_length)) && continue
            first_origin = origins[first_index]
            second_origin = origins[second_index]
            separated = any(1:K) do dimension
                first_origin[dimension] + first_length[dimension] <=
                second_origin[dimension] ||
                    second_origin[dimension] + second_length[dimension] <=
                    first_origin[dimension]
            end
            separated || return false
        end
    end
    return true
end

function xcsp_no_overlap(; origins, lengths, zero_ignored = true)
    return xcsp_no_overlap(origins, lengths, zero_ignored)
end

function concept_no_overlap(x, pair_vars, _, bool, ::Val{1})
    lengths, _ = _validated_no_overlap_arguments(x, pair_vars, 1)
    return xcsp_no_overlap(x, lengths, bool)
end

function concept_no_overlap(x, pair_vars, dim, bool, _)
    lengths, dimensions = _validated_no_overlap_arguments(x, pair_vars, dim)
    return iszero(_count_overlaps(x, lengths, dimensions, bool))
end

@usual function concept_no_overlap(
        x;
        pair_vars = ones(eltype(x), length(x)),
        dim = 1,
        bool = true
)
    idim = Int(dim)
    return concept_no_overlap(x, pair_vars, idim, bool, Val(idim))
end

@usual function concept_no_overlap_no_zero(
        x;
        pair_vars = ones(eltype(x), length(x)),
        dim = 1
)
    return concept_no_overlap(x; pair_vars, dim, bool = true)
end

@usual function concept_no_overlap_with_zero(
        x;
        pair_vars = ones(eltype(x), length(x)),
        dim = 1
)
    return concept_no_overlap(x; pair_vars, dim, bool = false)
end

"""Incremental one-dimensional `noOverlap` state owned by one constraint instance."""
mutable struct NoOverlapInvariant{O <: AbstractVector, L <: AbstractVector} <:
               AbstractInvariant
    origins::O
    lengths::L
    dimensions::Int
    zero_ignored::Bool
    binary::Bool
    overlaps::Int
    changed_marks::Vector{UInt32}
    generation::UInt32
end

supports_incremental(::ConceptError{:no_overlap}) = true
supports_incremental(::ConceptError{:no_overlap_no_zero}) = true
supports_incremental(::ConceptError{:no_overlap_with_zero}) = true

@inline function _tasks_overlap(origin_i, length_i, origin_j, length_j, zero_ignored)
    zero_ignored && (iszero(length_i) || iszero(length_j)) && return false
    return !(origin_i + length_i <= origin_j || origin_j + length_j <= origin_i)
end

@inline function _boxes_overlap(
        origins,
        lengths,
        dimensions::Int,
        first_task::Int,
        second_task::Int,
        zero_ignored::Bool,
)
    first_offset = (first_task - 1) * dimensions
    second_offset = (second_task - 1) * dimensions
    @inbounds for dimension in 1:dimensions
        first_index = first_offset + dimension
        second_index = second_offset + dimension
        first_length = lengths[first_index]
        second_length = lengths[second_index]
        zero_ignored && (iszero(first_length) || iszero(second_length)) && return false
        if origins[first_index] + first_length <= origins[second_index] ||
           origins[second_index] + second_length <= origins[first_index]
            return false
        end
    end
    return true
end

function _count_overlaps(origins, lengths, dimensions::Int, zero_ignored)
    tasks = length(origins) ÷ dimensions
    overlaps = 0
    @inbounds for first_task in 1:(tasks - 1)
        for second_task in (first_task + 1):tasks
            overlaps += _boxes_overlap(
                origins,
                lengths,
                dimensions,
                first_task,
                second_task,
                zero_ignored,
            )
        end
    end
    return overlaps
end

function _functional_no_overlap(error, values, X, parameters)
    return _functional_invariant(error, values, X, parameters)
end

function _no_overlap_lengths(pair_vars)
    return pair_vars isa AbstractMatrix ? @view(pair_vars[:, 1]) : pair_vars
end

function _validated_no_overlap_arguments(values, pair_vars, dim)
    dimensions = Int(dim)
    dimensions > 0 || throw(ArgumentError("noOverlap dimension must be positive"))
    length(values) % dimensions == 0 || throw(DimensionMismatch(
        "noOverlap coordinates must be divisible by the dimension"))
    lengths = _no_overlap_lengths(pair_vars)
    length(lengths) == length(values) || throw(DimensionMismatch(
        "noOverlap origins and lengths must have the same flattened length"))
    Base.require_one_based_indexing(values, lengths)
    return lengths, dimensions
end

function _initialize_no_overlap(error, values;
        X = nothing, pair_vars = ones(eltype(values), length(values)), dim = 1,
        bool = true, binary = true)
    parameters = (; pair_vars, dim, bool)
    dimensions = Int(dim)
    lengths_view = _no_overlap_lengths(pair_vars)
    if dimensions <= 0 || length(values) % max(dimensions, 1) != 0 ||
       length(lengths_view) != length(values) ||
       !all(length -> length isa Real && length >= zero(length), lengths_view)
        return _functional_no_overlap(error, values, X, parameters)
    end
    origins = collect(values)
    lengths = collect(lengths_view)
    overlaps = _count_overlaps(origins, lengths, dimensions, bool)
    tasks = length(origins) ÷ dimensions
    return NoOverlapInvariant(
        origins,
        lengths,
        dimensions,
        bool,
        binary,
        overlaps,
        zeros(UInt32, tasks),
        zero(UInt32),
    )
end

function initialize_invariant(error::ConceptError{:no_overlap}, values;
        X = nothing, pair_vars = ones(eltype(values), length(values)), dim = 1,
        bool = true)
    return _initialize_no_overlap(error, values; X, pair_vars, dim, bool)
end

function initialize_invariant(error::ConceptError{:no_overlap_no_zero}, values;
        X = nothing, pair_vars = ones(eltype(values), length(values)), dim = 1)
    return _initialize_no_overlap(error, values; X, pair_vars, dim, bool = true)
end

function initialize_invariant(error::ConceptError{:no_overlap_with_zero}, values;
        X = nothing, pair_vars = ones(eltype(values), length(values)), dim = 1)
    return _initialize_no_overlap(error, values; X, pair_vars, dim, bool = false)
end

@inline _no_overlap_value(invariant::NoOverlapInvariant, overlaps) =
    invariant.binary ? Float64(!iszero(overlaps)) : Float64(overlaps)

invariant_value(invariant::NoOverlapInvariant) =
    _no_overlap_value(invariant, invariant.overlaps)

function _next_changed_generation!(invariant::NoOverlapInvariant, changes)
    generation = if invariant.generation == typemax(UInt32)
        fill!(invariant.changed_marks, zero(UInt32))
        one(UInt32)
    else
        invariant.generation + one(UInt32)
    end
    invariant.generation = generation
    @inbounds for change in changes
        task = cld(change.position, invariant.dimensions)
        invariant.changed_marks[task] = generation
    end
    return generation
end

function _affected_overlaps(invariant::NoOverlapInvariant, generation)
    origins = invariant.origins
    lengths = invariant.lengths
    marks = invariant.changed_marks
    overlaps = 0
    @inbounds for first_task in eachindex(marks)
        marks[first_task] == generation || continue
        for second_task in eachindex(marks)
            first_task == second_task && continue
            marks[second_task] == generation && second_task < first_task && continue
            overlaps += _boxes_overlap(
                origins,
                lengths,
                invariant.dimensions,
                first_task,
                second_task,
                invariant.zero_ignored,
            )
        end
    end
    return overlaps
end

@inline function _apply_origins!(invariant::NoOverlapInvariant, changes)
    @inbounds for change in changes
        invariant.origins[change.position] = change.new_value
    end
    return nothing
end

@inline function _revert_origins!(invariant::NoOverlapInvariant, changes)
    @inbounds for change in Iterators.reverse(changes)
        invariant.origins[change.position] = change.old_value
    end
    return nothing
end

function candidate_value(
        invariant::NoOverlapInvariant, changes::Union{Tuple, AbstractVector})
    isempty(changes) && return invariant_value(invariant)
    generation = _next_changed_generation!(invariant, changes)
    previous = _affected_overlaps(invariant, generation)
    _apply_origins!(invariant, changes)
    try
        candidate = invariant.overlaps - previous +
                    _affected_overlaps(invariant, generation)
        return _no_overlap_value(invariant, candidate)
    finally
        _revert_origins!(invariant, changes)
    end
end

function commit_changes!(
        invariant::NoOverlapInvariant, changes::Union{Tuple, AbstractVector})
    isempty(changes) && return invariant_value(invariant)
    generation = _next_changed_generation!(invariant, changes)
    previous = _affected_overlaps(invariant, generation)
    _apply_origins!(invariant, changes)
    invariant.overlaps += _affected_overlaps(invariant, generation) - previous
    return invariant_value(invariant)
end

function rollback_changes!(
        invariant::NoOverlapInvariant, changes::Union{Tuple, AbstractVector})
    isempty(changes) && return invariant_value(invariant)
    generation = _next_changed_generation!(invariant, changes)
    current = _affected_overlaps(invariant, generation)
    _revert_origins!(invariant, changes)
    invariant.overlaps += _affected_overlaps(invariant, generation) - current
    return invariant_value(invariant)
end

function rebuild_invariant!(invariant::NoOverlapInvariant, values)
    length(values) == length(invariant.origins) ||
        throw(DimensionMismatch("noOverlap origins and lengths must have the same length"))
    copyto!(invariant.origins, values)
    invariant.overlaps = _count_overlaps(
        invariant.origins,
        invariant.lengths,
        invariant.dimensions,
        invariant.zero_ignored,
    )
    return invariant_value(invariant)
end

@testitem "noOverlap" tags=[:usual, :constraints, :no_overlap] begin
    c = USUAL_CONSTRAINTS[:no_overlap] |> concept
    e = USUAL_CONSTRAINTS[:no_overlap] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5])
    @test !c([1, 2, 3, 4, 1])
    @test c([1, 2, 4, 6, 3]; pair_vars = [1, 1, 1, 1, 1])
    @test c([1, 2, 4, 6, 3]; pair_vars = [1, 1, 1, 3, 1])
    @test !c([1, 2, 4, 6, 3]; pair_vars = [1, 1, 3, 1, 1])
    @test c(
        [1, 1, 1, 3, 5, 2, 7, 7, 5, 12, 8, 7];
        pair_vars = [2, 4, 1, 4, 2, 3, 5, 1, 2, 3, 3, 2],
        dim = 3
    )
    @test !c(
        [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4];
        pair_vars = [2, 4, 1, 4, 2, 3, 5, 1, 2, 3, 3, 2],
        dim = 3
    )
    @test c([0, 0, 1, 3]; pair_vars = [2, 2, 2, 2], dim = 2)
    @test !c([0, 0, 1, 1]; pair_vars = [2, 2, 2, 2], dim = 2)
    @test c([0, 0, 0, 1, 1, 3]; pair_vars = [2, 2, 2, 2, 2, 2], dim = 3)

    @test vs(c, e, [1, 2, 3, 4, 5])
    @test vs(c, e, [1, 2, 3, 4, 1])
    @test vs(c, e, [1, 2, 4, 6, 3]; pair_vars = [1, 1, 1, 1, 1])
    @test vs(c, e, [1, 2, 4, 6, 3]; pair_vars = [1, 1, 1, 3, 1])
    @test vs(c, e, [1, 2, 4, 6, 3]; pair_vars = [1, 1, 3, 1, 1])
    @test vs(
        c,
        e,
        [1, 1, 1, 3, 5, 2, 7, 7, 5, 12, 8, 7];
        pair_vars = [2, 4, 1, 4, 2, 3, 5, 1, 2, 3, 3, 2],
        dim = 3
    )
    @test vs(
        c,
        e,
        [1, 1, 1, 2, 2, 2, 3, 3, 3, 4, 4, 4];
        pair_vars = [2, 4, 1, 4, 2, 3, 5, 1, 2, 3, 3, 2],
        dim = 3
    )
    @test vs(c, e, [0, 0, 1, 3]; pair_vars = [2, 2, 2, 2], dim = 2)
    @test vs(c, e, [0, 0, 1, 1]; pair_vars = [2, 2, 2, 2], dim = 2)
end

@testitem "Incremental noOverlap" tags=[:constraints, :no_overlap, :invariant] begin
    import Test: @inferred, @test

    error = Constraints.make_error(:no_overlap)
    lengths = [2, 3, 1, 2]
    bound = Constraints.bind_error(error; pair_vars = lengths, dim = 1, bool = true)
    values = [0, 2, 5, 6]
    invariant = initialize_invariant(bound, values)
    @test supports_incremental(invariant)
    @test @inferred(invariant_value(invariant)) == bound(values)

    for assignment in Iterators.product(ntuple(_ -> 0:3, length(values))...)
        origins = collect(assignment)
        trial = initialize_invariant(bound, origins)
        @test invariant_value(trial) == bound(origins)
        for position in eachindex(origins), replacement in 0:3
            change = InvariantChange(position, origins[position], replacement)
            candidate = copy(origins)
            candidate[position] = replacement
            @test candidate_value(trial, change) == bound(candidate)
            @test invariant_value(trial) == bound(origins)
        end
        changes = (
            InvariantChange(1, origins[1], origins[3]),
            InvariantChange(3, origins[3], origins[1]),
        )
        candidate = copy(origins)
        candidate[1], candidate[3] = candidate[3], candidate[1]
        @test candidate_value(trial, changes) == bound(candidate)
        @test commit_changes!(trial, changes) == bound(candidate)
        @test rollback_changes!(trial, changes) == bound(origins)
    end

    zero_ignored = Constraints.bind_error(
        Constraints.make_error(:no_overlap_no_zero); pair_vars = [0, 2], dim = 1)
    zero_included = Constraints.bind_error(
        Constraints.make_error(:no_overlap_with_zero); pair_vars = [0, 2], dim = 1)
    @test invariant_value(initialize_invariant(zero_ignored, [1, 0])) ==
          zero_ignored([1, 0])
    @test invariant_value(initialize_invariant(zero_included, [1, 0])) ==
          zero_included([1, 0])

    multidimensional = Constraints.bind_error(error;
        pair_vars = [1, 1, 1, 1], dim = 2, bool = true)
    multidimensional_state = initialize_invariant(multidimensional, [0, 0, 2, 2])
    @test supports_incremental(multidimensional_state)
    @test invariant_value(multidimensional_state) == multidimensional([0, 0, 2, 2])
    multidimensional_change = InvariantChange(3, 2, 0)
    @test candidate_value(multidimensional_state, multidimensional_change) ==
          multidimensional([0, 0, 0, 2])
end

@testitem "Incremental noOverlap conflict penalty preserves its gradient" tags=[:constraints, :no_overlap, :invariant] begin
    import Test: @test

    penalty = penalty_f(:no_overlap, :pair_conflicts)
    @test penalty_profile(:no_overlap, :pair_conflicts).incremental
    bound = bind_error(penalty; pair_vars = fill(2, 4), dim = 1, bool = true)
    values = [0, 0, 0, 0]
    invariant = initialize_invariant(bound, values)
    @test supports_incremental(invariant)
    @test invariant_value(invariant) == 6.0
    change = InvariantChange(4, 0, 6)
    candidate = [0, 0, 0, 6]
    @test candidate_value(invariant, change) == bound(candidate) == 3.0
    @test commit_changes!(invariant, change) == 3.0
    @test rollback_changes!(invariant, change) == 6.0

    box_penalty = bind_error(
        penalty;
        pair_vars = [2, 2, 2, 2],
        dim = 2,
        bool = true,
    )
    box_values = [0, 0, 1, 1]
    box_invariant = initialize_invariant(box_penalty, box_values)
    @test supports_incremental(box_invariant)
    @test invariant_value(box_invariant) == box_penalty(box_values) == 1.0
end
