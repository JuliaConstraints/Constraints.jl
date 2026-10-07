"""
    PenaltyProfile

Metadata and evaluator for one solver-independent penalty associated with a constraint.
Profiles are deliberately separate from `Constraint.error`: adding candidates to the catalogue
does not silently change the package default or a solver's objective.
"""
struct PenaltyProfile{F <: Function}
    constraint::Symbol
    name::Symbol
    evaluator::F
    metric::Symbol
    exactness::Symbol
    provenance::String
    description::String
    incremental::Bool
end

"""Candidate penalty profiles indexed first by constraint, then by stable profile name."""
const PENALTY_PROFILES = Dict{Symbol, Dict{Symbol, PenaltyProfile}}()

"""Readable mathematical forms for the stable reference penalty profiles."""
const PENALTY_FORMULAS = Dict{Tuple{Symbol, Symbol}, String}()

"""
Empirical, explicit ICN-derived selection for the current XCSP3-core catalogue.

The mapping is a performance snapshot rather than a hidden package default. Callers opt in
through [`fastest_icn_penalty_profile`](@ref) or [`fastest_icn_penalty_f`](@ref).
"""
const FASTEST_ICN_PENALTIES = Dict{Symbol, Symbol}()

const _PENALTY_EXACTNESS = (:exact, :lower_bound, :surrogate)

"""
    register_penalty_profile!(constraint, name, evaluator; ...)

Register a named penalty without changing the constraint's default error. `exactness = :exact`
means exactly that the evaluator is zero iff the Boolean concept is satisfied; it does not claim
that the positive value is the minimum number of local-search moves for every possible domain.
"""
function register_penalty_profile!(constraint::Symbol, name::Symbol, evaluator::F;
        metric::Symbol,
        exactness::Symbol = :exact,
        provenance::AbstractString = "JuliaConstraints reference",
        description::AbstractString = "") where {F <: Function}
    haskey(USUAL_CONSTRAINTS, constraint) ||
        throw(ArgumentError("cannot attach a penalty to unknown constraint :$constraint"))
    exactness in _PENALTY_EXACTNESS || throw(ArgumentError(
        "exactness must be one of $(_PENALTY_EXACTNESS), got :$exactness"))
    profiles = get!(PENALTY_PROFILES, constraint) do
        Dict{Symbol, PenaltyProfile}()
    end
    haskey(profiles, name) && throw(ArgumentError(
        "penalty profile :$name is already registered for :$constraint"))
    profile = PenaltyProfile(constraint, name, evaluator, metric, exactness,
        String(provenance), String(description), supports_incremental(evaluator))
    profiles[name] = profile
    return profile
end

"""Return a named penalty profile. Selection is explicit: there is no hidden default profile."""
function penalty_profile(constraint::Symbol, name::Symbol)
    profiles = get(PENALTY_PROFILES, constraint, nothing)
    isnothing(profiles) && throw(KeyError(constraint))
    return profiles[name]
end

"""Return all registered profiles for a constraint, sorted by stable name."""
function penalty_profiles(constraint::Symbol)
    profiles = get(PENALTY_PROFILES, constraint, nothing)
    isnothing(profiles) && return PenaltyProfile[]
    return sort!(collect(values(profiles)); by = profile -> String(profile.name))
end

"""Return the callable evaluator of an explicitly selected penalty profile."""
penalty_f(constraint::Symbol, name::Symbol) = penalty_profile(constraint, name).evaluator
penalty_f(profile::PenaltyProfile) = profile.evaluator

"""Return the readable mathematical form recorded for a penalty profile, or `nothing`."""
penalty_formula(constraint::Symbol, name::Symbol) = name === :boolean ?
    raw"[\neg C(x)]" : get(PENALTY_FORMULAS, (constraint, name), nothing)
penalty_formula(profile::PenaltyProfile) = penalty_formula(profile.constraint, profile.name)

"""Return the explicitly selected fastest validated ICN-derived profile for a constraint."""
function fastest_icn_penalty_profile(constraint::Symbol)
    name = get(FASTEST_ICN_PENALTIES, constraint, nothing)
    isnothing(name) && throw(KeyError(constraint))
    return penalty_profile(constraint, name)
end

"""Return the evaluator of [`fastest_icn_penalty_profile`](@ref)."""
fastest_icn_penalty_f(constraint::Symbol) =
    penalty_f(fastest_icn_penalty_profile(constraint))

@inline function _strict_equality_cost(lhs::Integer, rhs::Integer)
    return 1.0
end

@inline function _strict_equality_cost(lhs::Real, rhs::Real)
    scale = max(abs(Float64(lhs)), abs(Float64(rhs)), 1.0)
    return eps(scale)
end

@inline _strict_equality_cost(lhs, rhs) = 1.0

"""Numerical violation of an XCSP3 scalar condition, with zero exactly on satisfaction."""
@inline function _condition_violation(lhs, rhs, op::F) where {F}
    op(lhs, rhs) && return 0.0
    if op === (==)
        return Float64(abs(lhs - rhs))
    elseif op === (!=) || op === (≠)
        return 1.0
    elseif op === (<=) || op === (≤)
        return Float64(lhs - rhs)
    elseif op === (>=) || op === (≥)
        return Float64(rhs - lhs)
    elseif op === (<)
        return lhs == rhs ? _strict_equality_cost(lhs, rhs) : Float64(lhs - rhs)
    elseif op === (>)
        return lhs == rhs ? _strict_equality_cost(lhs, rhs) : Float64(rhs - lhs)
    end
    return 1.0
end

@inline function _weighted_total(values, coefficients)
    length(values) == length(coefficients) ||
        throw(DimensionMismatch("coefficients and values must have the same length"))
    isempty(values) && return 0
    total = first(values) * first(coefficients)
    @inbounds for index in 2:length(values)
        total += values[index] * coefficients[index]
    end
    return total
end

struct SumValuePenalty <: Function end

function (::SumValuePenalty)(values; X = nothing, dom_size = nothing, op = ==,
        pair_vars = ones(eltype(values), length(values)), val)
    return _condition_violation(_weighted_total(values, pair_vars), val, op)
end

mutable struct SumValueInvariant{C <: AbstractVector, S, F, V} <: AbstractInvariant
    coefficients::C
    total::S
    operator::F
    target::V
end

supports_incremental(::SumValuePenalty) = true

function initialize_invariant(::SumValuePenalty, values; X = nothing, op = ==,
        pair_vars = ones(eltype(values), length(values)), val)
    coefficients = collect(pair_vars)
    total = _weighted_total(values, coefficients)
    return SumValueInvariant(coefficients, total, op, val)
end

function invariant_value(invariant::SumValueInvariant)
    _condition_violation(invariant.total, invariant.target, invariant.operator)
end

@inline function _sum_value_delta(
        invariant::SumValueInvariant, changes::Union{Tuple, AbstractVector})
    delta = zero(invariant.total)
    @inbounds for change in changes
        delta += invariant.coefficients[change.position] *
                 (change.new_value - change.old_value)
    end
    return delta
end

function candidate_value(
        invariant::SumValueInvariant, changes::Union{Tuple, AbstractVector})
    total = invariant.total + _sum_value_delta(invariant, changes)
    return _condition_violation(total, invariant.target, invariant.operator)
end

function commit_changes!(
        invariant::SumValueInvariant, changes::Union{Tuple, AbstractVector})
    invariant.total += _sum_value_delta(invariant, changes)
    return invariant_value(invariant)
end

function rollback_changes!(
        invariant::SumValueInvariant, changes::Union{Tuple, AbstractVector})
    invariant.total -= _sum_value_delta(invariant, changes)
    return invariant_value(invariant)
end

function rebuild_invariant!(invariant::SumValueInvariant, values)
    invariant.total = _weighted_total(values, invariant.coefficients)
    return invariant_value(invariant)
end

@inline function _ignored(value, ::Nothing)
    return false
end

@inline function _ignored(value, vals)
    @inbounds for index in axes(vals, 1)
        vals[index, 1] == value && return true
    end
    return false
end

struct AllDifferentRepairPenalty <: Function end
struct AllDifferentPairPenalty <: Function end

function (::AllDifferentRepairPenalty)(values; X = nothing, dom_size = nothing, vals = nothing)
    counts = Dict{eltype(values), Int}()
    duplicates = 0
    for value in values
        _ignored(value, vals) && continue
        count = get(counts, value, 0)
        duplicates += !iszero(count)
        counts[value] = count + 1
    end
    return Float64(duplicates)
end

function (::AllDifferentPairPenalty)(values; X = nothing, dom_size = nothing, vals = nothing)
    counts = Dict{eltype(values), Int}()
    conflicts = 0
    for value in values
        _ignored(value, vals) && continue
        count = get(counts, value, 0)
        conflicts += count
        counts[value] = count + 1
    end
    return Float64(conflicts)
end

mutable struct AllDifferentPenaltyInvariant{Mode, T, I <: AbstractSet{T}} <:
               AbstractInvariant
    counts::Dict{T, Int}
    ignored::I
    violation::Int
end

supports_incremental(::AllDifferentRepairPenalty) = true
supports_incremental(::AllDifferentPairPenalty) = true

function _initialize_all_different_penalty(::Val{Mode}, values, vals) where {Mode}
    T = eltype(values)
    ignored = _ignored_values(T, vals)
    counts = Dict{T, Int}()
    violation = 0
    for value in values
        value in ignored && continue
        count = get(counts, value, 0)
        violation += Mode === :repair ? !iszero(count) : count
        counts[value] = count + 1
    end
    return AllDifferentPenaltyInvariant{Mode, T, typeof(ignored)}(
        counts, ignored, violation)
end

function initialize_invariant(
        ::AllDifferentRepairPenalty, values; X = nothing, vals = nothing)
    return _initialize_all_different_penalty(Val(:repair), values, vals)
end

function initialize_invariant(
        ::AllDifferentPairPenalty, values; X = nothing, vals = nothing)
    return _initialize_all_different_penalty(Val(:pairs), values, vals)
end

invariant_value(invariant::AllDifferentPenaltyInvariant) = Float64(invariant.violation)

@inline function _remove_value!(invariant::AllDifferentPenaltyInvariant{Mode}, value) where {Mode}
    value in invariant.ignored && return nothing
    count = invariant.counts[value]
    invariant.violation -= Mode === :repair ? count > 1 : count - 1
    if count == 1
        delete!(invariant.counts, value)
    else
        invariant.counts[value] = count - 1
    end
    return nothing
end

@inline function _add_value!(invariant::AllDifferentPenaltyInvariant{Mode}, value) where {Mode}
    value in invariant.ignored && return nothing
    count = get(invariant.counts, value, 0)
    invariant.violation += Mode === :repair ? !iszero(count) : count
    invariant.counts[value] = count + 1
    return nothing
end

@inline function _apply_change!(
        invariant::AllDifferentPenaltyInvariant, change::InvariantChange)
    change.old_value == change.new_value && return nothing
    _remove_value!(invariant, change.old_value)
    _add_value!(invariant, change.new_value)
    return nothing
end

@inline function _revert_change!(
        invariant::AllDifferentPenaltyInvariant, change::InvariantChange)
    change.old_value == change.new_value && return nothing
    _remove_value!(invariant, change.new_value)
    _add_value!(invariant, change.old_value)
    return nothing
end

function candidate_value(invariant::AllDifferentPenaltyInvariant,
        changes::Union{Tuple, AbstractVector})
    foreach(change -> _apply_change!(invariant, change), changes)
    value = invariant_value(invariant)
    foreach(change -> _revert_change!(invariant, change), Iterators.reverse(changes))
    return value
end

function commit_changes!(invariant::AllDifferentPenaltyInvariant,
        changes::Union{Tuple, AbstractVector})
    foreach(change -> _apply_change!(invariant, change), changes)
    return invariant_value(invariant)
end

function rollback_changes!(invariant::AllDifferentPenaltyInvariant,
        changes::Union{Tuple, AbstractVector})
    foreach(change -> _revert_change!(invariant, change), Iterators.reverse(changes))
    return invariant_value(invariant)
end

function rebuild_invariant!(invariant::AllDifferentPenaltyInvariant{Mode}, values) where {Mode}
    empty!(invariant.counts)
    invariant.violation = 0
    for value in values
        _add_value!(invariant, value)
    end
    return invariant_value(invariant)
end

struct AllEqualRepairPenalty <: Function end
struct AllEqualPairPenalty <: Function end

@inline function _all_equal_transformed(value, pair_value, op)
    return op(value, pair_value)
end

function _all_equal_counts(values, pair_vars, op)
    counts = Dict{Any, Int}()
    maximum_count = 0
    if iszero(pair_vars)
        for value in values
            count = get(counts, value, 0) + 1
            counts[value] = count
            maximum_count = max(maximum_count, count)
        end
    else
        length(values) == length(pair_vars) || throw(DimensionMismatch(
            "paired values and values must have the same length"))
        for index in eachindex(values, pair_vars)
            value = _all_equal_transformed(values[index], pair_vars[index], op)
            count = get(counts, value, 0) + 1
            counts[value] = count
            maximum_count = max(maximum_count, count)
        end
    end
    return counts, maximum_count
end

function (::AllEqualRepairPenalty)(values; X = nothing, dom_size = nothing, val = nothing,
        pair_vars = zeros(eltype(values), length(values)), op = +)
    if !isnothing(val)
        mismatches = 0
        if iszero(pair_vars)
            for value in values
                mismatches += value != val
            end
        else
            length(values) == length(pair_vars) || throw(DimensionMismatch(
                "paired values and values must have the same length"))
            for index in eachindex(values, pair_vars)
                mismatches += op(values[index], pair_vars[index]) != val
            end
        end
        return Float64(mismatches)
    end
    _, maximum_count = _all_equal_counts(values, pair_vars, op)
    return Float64(length(values) - maximum_count)
end

function (::AllEqualPairPenalty)(values; X = nothing, dom_size = nothing, val = nothing,
        pair_vars = zeros(eltype(values), length(values)), op = +)
    if !isnothing(val)
        return AllEqualRepairPenalty()(values; val, pair_vars, op)
    end
    counts, _ = _all_equal_counts(values, pair_vars, op)
    total_pairs = length(values) * (length(values) - 1) ÷ 2
    equal_pairs = sum(count * (count - 1) ÷ 2 for count in Base.values(counts))
    return Float64(total_pairs - equal_pairs)
end

struct CountValuePenalty{FixedOperator} <: Function end

function _count_occurrences(values, vals)
    occurrences = 0
    for value in values
        value in vals && (occurrences += 1)
    end
    return occurrences
end

function (::CountValuePenalty{:parameter})(values; X = nothing, dom_size = nothing,
        vals, op, val)
    return _condition_violation(_count_occurrences(values, vals), val, op)
end

function (::CountValuePenalty{:at_least})(
        values; X = nothing, dom_size = nothing, vals, val)
    return _condition_violation(_count_occurrences(values, vals), val, >=)
end

function (::CountValuePenalty{:at_most})(values; X = nothing, dom_size = nothing, vals, val)
    return _condition_violation(_count_occurrences(values, vals), val, <=)
end

function (::CountValuePenalty{:exactly})(values; X = nothing, dom_size = nothing, vals, val)
    return _condition_violation(_count_occurrences(values, vals), val, ==)
end

struct NValuesValuePenalty <: Function end

function (::NValuesValuePenalty)(values; X = nothing, dom_size = nothing, op = ==,
        val, vals = nothing)
    return _condition_violation(_nvalues_count(values, vals), val, op)
end

struct CardinalityValuePenalty{Closed} <: Function end

@inline function _occurrence_violation(count, occurs)
    if occurs isa Integer
        return Float64(abs(count - occurs))
    end
    count in occurs && return 0.0
    isempty(occurs) && return 1.0
    return count < minimum(occurs) ? Float64(minimum(occurs) - count) :
           Float64(count - maximum(occurs))
end

function _cardinality_parameters(vals)
    values = vals[:, 1]
    occurs = if size(vals, 2) == 1
        ones(Int, size(vals, 1))
    elseif size(vals, 2) >= 3
        [vals[index, 2]:(vals[index, 2] <= vals[index, 3] ? 1 : -1):vals[index, 3]
         for index in axes(vals, 1)]
    else
        vals[:, 2]
    end
    return values, occurs
end

function _cardinality_value_penalty(values_to_check, vals, closed)
    constrained_values, occurs = _cardinality_parameters(vals)
    counts = Dict(value => 0 for value in constrained_values)
    outside = 0
    for value in values_to_check
        if haskey(counts, value)
            counts[value] += 1
        else
            outside += closed
        end
    end
    violation = outside
    for index in eachindex(constrained_values)
        violation += _occurrence_violation(counts[constrained_values[index]], occurs[index])
    end
    return Float64(violation)
end

function (::CardinalityValuePenalty{:parameter})(values; X = nothing, dom_size = nothing,
        bool = false, vals)
    return _cardinality_value_penalty(values, vals, bool)
end

function (::CardinalityValuePenalty{:closed})(values; X = nothing, dom_size = nothing, vals)
    return _cardinality_value_penalty(values, vals, true)
end

function (::CardinalityValuePenalty{:open})(values; X = nothing, dom_size = nothing, vals)
    return _cardinality_value_penalty(values, vals, false)
end

struct InstantiationPenalty{Metric} <: Function end

function (::InstantiationPenalty{:hamming})(values; X = nothing, dom_size = nothing,
        pair_vars)
    length(values) == length(pair_vars) || throw(DimensionMismatch(
        "instantiation values and target values must have the same length"))
    mismatches = 0
    @inbounds for index in eachindex(values, pair_vars)
        mismatches += values[index] != pair_vars[index]
    end
    return Float64(mismatches)
end

function (::InstantiationPenalty{:manhattan})(values; X = nothing, dom_size = nothing,
        pair_vars)
    length(values) == length(pair_vars) || throw(DimensionMismatch(
        "instantiation values and target values must have the same length"))
    distance = 0.0
    @inbounds for index in eachindex(values, pair_vars)
        distance += abs(values[index] - pair_vars[index])
    end
    return distance
end

struct ExtremumValuePenalty{Kind} <: Function end

function (::ExtremumValuePenalty{:maximum})(values; X = nothing, dom_size = nothing,
        op = ==, val)
    return _condition_violation(maximum(values), val, op)
end

function (::ExtremumValuePenalty{:minimum})(values; X = nothing, dom_size = nothing,
        op = ==, val)
    return _condition_violation(minimum(values), val, op)
end

struct OrderedValuePenalty{FixedOperator} <: Function end

@inline _ordered_operator(::OrderedValuePenalty{:parameter}, op) = op
@inline _ordered_operator(::OrderedValuePenalty{:increasing}, op) = (<=)
@inline _ordered_operator(::OrderedValuePenalty{:decreasing}, op) = (>=)
@inline _ordered_operator(::OrderedValuePenalty{:strictly_increasing}, op) = (<)
@inline _ordered_operator(::OrderedValuePenalty{:strictly_decreasing}, op) = (>)

function (penalty::OrderedValuePenalty)(values; X = nothing, dom_size = nothing,
        op = <=, pair_vars = nothing)
    operator = _ordered_operator(penalty, op)
    violation = 0.0
    for index in firstindex(values):(lastindex(values) - 1)
        lhs = isnothing(pair_vars) ? values[index] : values[index] + pair_vars[index]
        violation += _condition_violation(lhs, values[index + 1], operator)
    end
    return violation
end

struct ElementValuePenalty <: Function end

@inline function _index_violation(index, length)
    index < 1 && return Float64(1 - index)
    index > length && return Float64(index - length)
    return 0.0
end

struct ChannelIndexPenalty <: Function end
struct CircuitGraphPenalty <: Function end
struct DistDifferentPenalty <: Function end

function (::DistDifferentPenalty)(values; X = nothing, dom_size = nothing)
    Base.require_one_based_indexing(values)
    length(values) == 4 || throw(DimensionMismatch(
        "dist_different requires exactly four values",
    ))
    return Float64(abs(values[1] - values[2]) == abs(values[3] - values[4]))
end

function (::ChannelIndexPenalty)(values; X = nothing, dom_size = nothing,
        dim = 1, id = nothing)
    Base.require_one_based_indexing(values)
    if !isnothing(id)
        id isa Integer || return 1.0
        1 ≤ id ≤ length(values) || return Float64(
            id < 1 ? 1 - id : id - length(values))
        violation = 0.0
        @inbounds for index in eachindex(values)
            violation += abs(Float64(values[index]) - (index == id))
        end
        return violation
    end

    dim isa Integer && dim in (1, 2) || return 1.0
    length(values) % dim == 0 || return 1.0
    blocks = Int(dim)
    width = length(values) ÷ blocks
    violation = 0.0
    @inbounds for block in 0:(blocks - 1)
        source_offset = block * width
        target_offset = ((block + 1) % blocks) * width
        for local_index in 1:width
            indirect_index = values[source_offset + local_index]
            if !(indirect_index isa Integer && 1 ≤ indirect_index ≤ width)
                violation += local_index
                continue
            end
            violation += abs(Float64(
                values[target_offset + Int(indirect_index)] - local_index))
        end
    end
    return violation
end

function _predecessor_balance(values)
    n = length(values)
    counts = zeros(Int, n)
    violation = 0.0
    @inbounds for successor in values
        if successor isa Integer && 1 <= successor <= n
            counts[Int(successor)] += 1
        end
    end
    @inbounds for count in counts
        violation += abs(count - 1)
    end
    return violation
end

function _orbit_exclusions(values)
    n = length(values)
    first_active = findfirst(index -> values[index] != index, eachindex(values))
    isnothing(first_active) && return 1.0

    visited = falses(n)
    current = first_active
    while current isa Integer && 1 <= current <= n && !visited[Int(current)] &&
          values[Int(current)] != current
        visited[Int(current)] = true
        current = values[Int(current)]
    end
    exclusions = 0
    @inbounds for index in eachindex(values)
        exclusions += values[index] != index && !visited[index]
    end
    return Float64(exclusions)
end

"""Exact zero-set penalty for one functional-graph orbit plus optional size condition."""
function (::CircuitGraphPenalty)(values; X = nothing, dom_size = nothing,
        op = >=, val = 2)
    Base.require_one_based_indexing(values)
    active_count = count(index -> values[index] != index, eachindex(values))
    return _predecessor_balance(values) + _orbit_exclusions(values) +
           _condition_violation(active_count, val, op)
end

function _element_value_penalty(values, id, op, val)
    violation = _index_violation(id, length(values))
    iszero(violation) || return violation
    return _condition_violation(values[id], val, op)
end

function (::ElementValuePenalty)(values; X = nothing, dom_size = nothing, id = nothing,
        op = ==, val = nothing)
    if isnothing(id) && isnothing(val)
        length(values) >= 3 || return 1.0
        return _element_value_penalty(
            @view(values[2:(end - 1)]), values[1], op, values[end])
    elseif isnothing(id)
        length(values) >= 2 || return 1.0
        return _element_value_penalty(@view(values[2:end]), values[1], op, val)
    elseif isnothing(val)
        length(values) >= 2 || return 1.0
        return _element_value_penalty(@view(values[1:(end - 1)]), id, op, values[end])
    end
    return _element_value_penalty(values, id, op, val)
end

struct SupportsHammingPenalty <: Function end
struct ConflictsEscapePenalty <: Function end
struct ExtensionHammingPenalty <: Function end

function (::SupportsHammingPenalty)(values; X = nothing, dom_size = nothing, pair_vars)
    isempty(pair_vars) && return 1.0
    minimum_distance = typemax(Int)
    for tuple in pair_vars
        length(tuple) == length(values) || continue
        distance = 0
        @inbounds for index in eachindex(values, tuple)
            distance += values[index] != tuple[index]
        end
        minimum_distance = min(minimum_distance, distance)
        iszero(minimum_distance) && return 0.0
    end
    return minimum_distance == typemax(Int) ? 1.0 : Float64(minimum_distance)
end

function (::ConflictsEscapePenalty)(values; X = nothing, dom_size = nothing, pair_vars)
    return Float64(values in pair_vars)
end

function (::ExtensionHammingPenalty)(values; X = nothing, dom_size = nothing, pair_vars)
    if pair_vars isa AbstractVector{<:AbstractVector}
        return SupportsHammingPenalty()(values; X, dom_size, pair_vars)
    end
    supports, conflicts = pair_vars
    support_cost = SupportsHammingPenalty()(values; X, dom_size, pair_vars = supports)
    conflict_cost = ConflictsEscapePenalty()(values; X, dom_size, pair_vars = conflicts)
    return min(support_cost, conflict_cost)
end

struct LanguageHammingPenalty <: Function end

function (::LanguageHammingPenalty)(values; X = nothing, dom_size = nothing, language)
    language_distance = getfield(ConstraintCommons, :language_distance)
    # LocalSearchSolvers also supplies X as an ICN numerical scratch matrix.
    # It is not a language DP workspace. Reuse only a correctly typed workspace;
    # the two-argument API allocates an owned one when called by such a solver.
    distance = X isa ConstraintCommons.LanguageDistanceWorkspace ?
               language_distance(language, values, X) : language_distance(language, values)
    return Float64(distance)
end

struct NoOverlapConflictPenalty{FixedZeroIgnored} <: Function end

@inline _zero_ignored(::NoOverlapConflictPenalty{:parameter}, bool) = bool
@inline _zero_ignored(::NoOverlapConflictPenalty{:ignored}, bool) = true
@inline _zero_ignored(::NoOverlapConflictPenalty{:included}, bool) = false

supports_incremental(::NoOverlapConflictPenalty) = true

function initialize_invariant(
        penalty::NoOverlapConflictPenalty,
        values;
        X = nothing,
        pair_vars = ones(eltype(values), length(values)),
        dim = 1,
        bool = true,
)
    return _initialize_no_overlap(
        penalty,
        values;
        X,
        pair_vars,
        dim,
        bool = _zero_ignored(penalty, bool),
        binary = false,
    )
end

function (penalty::NoOverlapConflictPenalty)(values; X = nothing, dom_size = nothing,
        pair_vars = ones(eltype(values), length(values)), dim = 1, bool = true)
    lengths, dimensions = _validated_no_overlap_arguments(values, pair_vars, dim)
    zero_ignored = _zero_ignored(penalty, bool)
    return Float64(_count_overlaps(values, lengths, dimensions, zero_ignored))
end

struct CumulativeEventPenalty{Reduction} <: Function end

function _cumulative_data(pair_vars, values)
    if pair_vars isa AbstractMatrix
        size(pair_vars) == (2, length(values)) || throw(DimensionMismatch(
            "cumulative task matrix must have two rows and one column per origin"))
        return @view(pair_vars[1, :]), @view(pair_vars[2, :])
    end
    length(pair_vars) == length(values) || throw(DimensionMismatch(
        "cumulative task data and origins must have the same length"))
    return pair_vars, pair_vars
end

function _cumulative_event_value!(::Val{Reduction}, events, values, lengths, heights,
        op, val) where {Reduction}
    length(events) == 2length(values) || throw(DimensionMismatch(
        "cumulative event workspace must contain exactly two events per task"))
    @inbounds for index in eachindex(values)
        event_index = 2index - 1
        events[event_index] = (values[index], heights[index])
        events[event_index + 1] = (values[index] + lengths[index], -heights[index])
    end
    sort!(events; alg = Base.Sort.QuickSort)

    usage = zero(eltype(heights))
    violation = 0.0
    event = firstindex(events)
    @inbounds while event <= lastindex(events)
        time = events[event][1]
        while event <= lastindex(events) && events[event][1] == time
            usage += events[event][2]
            event += 1
        end
        current = _condition_violation(usage, val, op)
        if Reduction === :maximum
            violation = max(violation, current)
        elseif Reduction === :sum
            violation += current
        elseif event <= lastindex(events)
            width = events[event][1] - time
            if Reduction === :area
                violation += Float64(width) * current
            elseif Reduction === :quadratic_area
                violation += Float64(width) * current * current
            else
                throw(ArgumentError("unknown cumulative event reduction :$Reduction"))
            end
        elseif Reduction === :area || Reduction === :quadratic_area
            # One zero-load exterior witness is sufficient to preserve the exact zero set.
            violation += current
        end
    end
    return violation
end

function (penalty::CumulativeEventPenalty{Reduction})(values; X = nothing,
        dom_size = nothing, pair_vars = ones(eltype(values), (2, length(values))),
        op = <=, val) where {Reduction}
    lengths, heights = _cumulative_data(pair_vars, values)
    time_type = promote_type(eltype(values), eltype(lengths))
    events = Vector{Tuple{time_type, eltype(heights)}}(undef, 2length(values))
    return _cumulative_event_value!(
        Val(Reduction), events, values, lengths, heights, op, val)
end

mutable struct CumulativePenaltyInvariant{
    R,
    O <: AbstractVector,
    L <: AbstractVector,
    H <: AbstractVector,
    F,
    V,
    E <: AbstractVector,
} <: AbstractInvariant
    reduction::R
    origins::O
    lengths::L
    heights::H
    operator::F
    target::V
    events::E
    current::Float64
end

supports_incremental(::CumulativeEventPenalty) = true

function _cumulative_penalty_value!(invariant::CumulativePenaltyInvariant)
    return _cumulative_event_value!(invariant.reduction, invariant.events,
        invariant.origins, invariant.lengths, invariant.heights,
        invariant.operator, invariant.target)
end

function initialize_invariant(penalty::CumulativeEventPenalty{Reduction}, values;
        X = nothing,
        pair_vars = ones(eltype(values), (2, length(values))),
        op = <=,
        val,
) where {Reduction}
    lengths, heights = _cumulative_data(pair_vars, values)
    origins = collect(values)
    lengths_copy = collect(lengths)
    heights_copy = collect(heights)
    time_type = promote_type(eltype(origins), eltype(lengths_copy))
    events = Vector{Tuple{time_type, eltype(heights_copy)}}(
        undef, 2length(origins))
    invariant = CumulativePenaltyInvariant(
        Val(Reduction), origins, lengths_copy, heights_copy, op, val, events, 0.0)
    invariant.current = _cumulative_penalty_value!(invariant)
    return invariant
end

invariant_value(invariant::CumulativePenaltyInvariant) = invariant.current

function candidate_value(
        invariant::CumulativePenaltyInvariant,
        changes::Union{Tuple, AbstractVector},
)
    isempty(changes) && return invariant.current
    @inbounds for change in changes
        invariant.origins[change.position] = change.new_value
    end
    try
        return _cumulative_penalty_value!(invariant)
    finally
        @inbounds for change in Iterators.reverse(changes)
            invariant.origins[change.position] = change.old_value
        end
    end
end

function commit_changes!(
        invariant::CumulativePenaltyInvariant,
        changes::Union{Tuple, AbstractVector},
)
    @inbounds for change in changes
        invariant.origins[change.position] = change.new_value
    end
    invariant.current = _cumulative_penalty_value!(invariant)
    return invariant.current
end

function rollback_changes!(
        invariant::CumulativePenaltyInvariant,
        changes::Union{Tuple, AbstractVector},
)
    @inbounds for change in Iterators.reverse(changes)
        invariant.origins[change.position] = change.old_value
    end
    invariant.current = _cumulative_penalty_value!(invariant)
    return invariant.current
end

function rebuild_invariant!(invariant::CumulativePenaltyInvariant, values)
    length(values) == length(invariant.origins) || throw(DimensionMismatch(
        "cumulative origins and task data must have the same length"))
    copyto!(invariant.origins, values)
    invariant.current = _cumulative_penalty_value!(invariant)
    return invariant.current
end

function _register_reference_penalties!()
    for constraint in keys(USUAL_CONSTRAINTS)
        boolean = concept_error(constraint, concept(USUAL_CONSTRAINTS[constraint]))
        register_penalty_profile!(constraint, :boolean, boolean;
            metric = :boolean,
            provenance = "existing Constraints.jl concept error",
            description = "Unit cost for every invalid assignment.")
    end

    register_penalty_profile!(:all_different, :repair, AllDifferentRepairPenalty();
        metric = :hamming,
        provenance = "global-constraint violation measure",
        description = "Repeated values beyond the first occurrence (n minus distinct values).")
    register_penalty_profile!(:all_different, :pair_conflicts, AllDifferentPairPenalty();
        metric = :decomposition,
        provenance = "pairwise disequality decomposition",
        description = "Number of equal unordered variable pairs.")
    register_penalty_profile!(:all_equal, :repair, AllEqualRepairPenalty();
        metric = :hamming,
        provenance = "global-constraint violation measure",
        description = "Variables outside the largest equal-value class, or target mismatches.")
    register_penalty_profile!(:all_equal, :pair_conflicts, AllEqualPairPenalty();
        metric = :decomposition,
        provenance = "pairwise equality decomposition",
        description = "Number of unequal unordered variable pairs.")
    register_penalty_profile!(:sum, :value, SumValuePenalty();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Distance of the weighted total to the scalar condition.")
    register_penalty_profile!(:count, :value, CountValuePenalty{:parameter}();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Distance of the occurrence count to the scalar condition.")
    register_penalty_profile!(:at_least, :value, CountValuePenalty{:at_least}();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Missing occurrences below the lower bound.")
    register_penalty_profile!(:at_most, :value, CountValuePenalty{:at_most}();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Excess occurrences above the upper bound.")
    register_penalty_profile!(:exactly, :value, CountValuePenalty{:exactly}();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Absolute deviation from the required occurrence count.")
    register_penalty_profile!(:nvalues, :value, NValuesValuePenalty();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Distance of the number of distinct values to the scalar condition.")
    register_penalty_profile!(:cardinality, :value, CardinalityValuePenalty{:parameter}();
        metric = :decomposition,
        provenance = "global-cardinality violation measure",
        description = "Sum of occurrence-bound violations, plus out-of-set values when closed.")
    register_penalty_profile!(
        :cardinality_closed, :value, CardinalityValuePenalty{:closed}();
        metric = :decomposition,
        provenance = "global-cardinality violation measure",
        description = "Closed global-cardinality occurrence and membership violations.")
    register_penalty_profile!(:cardinality_open, :value, CardinalityValuePenalty{:open}();
        metric = :decomposition,
        provenance = "global-cardinality violation measure",
        description = "Open global-cardinality occurrence violations.")
    register_penalty_profile!(:instantiation, :hamming, InstantiationPenalty{:hamming}();
        metric = :hamming,
        provenance = "componentwise equality decomposition",
        description = "Number of target mismatches.")
    register_penalty_profile!(
        :instantiation, :manhattan, InstantiationPenalty{:manhattan}();
        metric = :manhattan,
        provenance = "componentwise numerical distance",
        description = "Sum of absolute distances to numerical targets.")
    register_penalty_profile!(:maximum, :value, ExtremumValuePenalty{:maximum}();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Distance of the maximum value to the scalar condition.")
    register_penalty_profile!(:minimum, :value, ExtremumValuePenalty{:minimum}();
        metric = :manhattan,
        provenance = "scalar-condition violation measure",
        description = "Distance of the minimum value to the scalar condition.")
    for (constraint, kind) in ((:ordered, :parameter), (:increasing, :increasing),
        (:decreasing, :decreasing), (:strictly_increasing, :strictly_increasing),
        (:strictly_decreasing, :strictly_decreasing))
        register_penalty_profile!(
            constraint, :adjacent_residual, OrderedValuePenalty{kind}();
            metric = :decomposition,
            provenance = "adjacent scalar-condition decomposition",
            description = "Sum of adjacent-order residuals.")
    end
    register_penalty_profile!(:element, :value, ElementValuePenalty();
        metric = :manhattan,
        provenance = "element scalar-condition violation measure",
        description = "Index-bound distance or selected-value condition residual.")
    register_penalty_profile!(:channel, :index_l1, ChannelIndexPenalty();
        metric = :manhattan,
        provenance = "indexed-relation decomposition",
        description = "L1 residual of one-based indirect indexing or an indexed indicator.")
    register_penalty_profile!(:circuit, :graph_residual, CircuitGraphPenalty();
        metric = :decomposition,
        provenance = "functional-graph decomposition",
        description = "Predecessor balance, orbit coverage, and circuit-size residual.")
    register_penalty_profile!(:dist_different, :pair_distance_collision,
        DistDifferentPenalty();
        metric = :decomposition,
        provenance = "disjoint-pair distance decomposition",
        description = "Unit collision cost when the two disjoint-pair distances coincide.")
    register_penalty_profile!(:supports, :hamming, SupportsHammingPenalty();
        metric = :hamming,
        provenance = "nearest allowed tuple distance",
        description = "Minimum component mismatch count to a supported tuple.")
    register_penalty_profile!(:conflicts, :escape, ConflictsEscapePenalty();
        metric = :hamming,
        provenance = "forbidden tuple escape distance",
        description = "One required component change for an exactly forbidden tuple.")
    register_penalty_profile!(:extension, :grouped_hamming, ExtensionHammingPenalty();
        metric = :hamming,
        provenance = "validated ICN row composition",
        description = "Minimum of the support distance and conflict-escape cost.")
    if isdefined(ConstraintCommons, :language_distance)
        for constraint in (:regular, :mdd)
            register_penalty_profile!(constraint, :hamming, LanguageHammingPenalty();
                metric = :hamming,
                provenance = "dynamic-programming language distance",
                description = "Minimum same-length symbol substitutions to an accepted path.")
        end
    end
    register_penalty_profile!(
        :no_overlap, :pair_conflicts, NoOverlapConflictPenalty{:parameter}();
        metric = :decomposition,
        provenance = "pairwise disjunctive-resource decomposition",
        description = "Number of overlapping task or box pairs.")
    register_penalty_profile!(
        :no_overlap_no_zero, :pair_conflicts, NoOverlapConflictPenalty{:ignored}();
        metric = :decomposition,
        provenance = "pairwise disjunctive-resource decomposition",
        description = "Number of overlapping non-zero task or box pairs.")
    register_penalty_profile!(
        :no_overlap_with_zero, :pair_conflicts, NoOverlapConflictPenalty{:included}();
        metric = :decomposition,
        provenance = "pairwise disjunctive-resource decomposition",
        description = "Number of overlapping task or box pairs, including zero lengths.")
    register_penalty_profile!(
        :cumulative, :maximum_event_residual, CumulativeEventPenalty{:maximum}();
        metric = :resource_overload,
        provenance = "cumulative resource overload",
        description = "Maximum scalar-condition violation over sorted resource events.")
    register_penalty_profile!(
        :cumulative, :sum_event_residual, CumulativeEventPenalty{:sum}();
        metric = :decomposition,
        provenance = "cumulative resource overload",
        description = "Sum of scalar-condition violations over sorted resource events.")
    register_penalty_profile!(
        :cumulative, :area_residual, CumulativeEventPenalty{:area}();
        metric = :resource_overload,
        provenance = "sweep-based linear cumulative overload",
        description = "Time-integral of scalar-condition violation over the event profile.")
    register_penalty_profile!(
        :cumulative, :quadratic_area_residual,
        CumulativeEventPenalty{:quadratic_area}();
        metric = :quadratic_resource_overload,
        provenance = "quadratic cumulative overload",
        description = "Time-integral of squared scalar-condition violation over the event profile.")
    return nothing
end

_register_reference_penalties!()

function _register_reference_formulae!()
    merge!(PENALTY_FORMULAS, Dict(
        (:all_different, :repair) => raw"\sum_v \max(c_v-1,0)",
        (:all_different, :pair_conflicts) => raw"\sum_v \binom{c_v}{2}",
        (:all_equal, :repair) => raw"\begin{cases}n-\max_v c_v,&v=\varnothing\\\sum_i[g_i\ne v],&\text{otherwise}\end{cases}",
        (:all_equal, :pair_conflicts) => raw"\binom{n}{2}-\sum_v\binom{c_v}{2}",
        (:sum, :value) => raw"r_{\circ}\!\left(\sum_i p_i x_i, v\right)",
        (:count, :value) => raw"r_{\circ}\!\left(\sum_i [x_i\in V], v\right)",
        (:at_least, :value) => raw"[v-\sum_i[x_i\in V]]_+",
        (:at_most, :value) => raw"[\sum_i[x_i\in V]-v]_+",
        (:exactly, :value) => raw"\left\lvert\sum_i[x_i\in V]-v\right\rvert",
        (:nvalues, :value) => raw"r_{\circ}\!\left(\lvert\operatorname{distinct}(x\setminus V)\rvert,v\right)",
        (:cardinality, :value) => raw"\sum_j d(c_{V_j},O_j)+b\sum_i[x_i\notin V]",
        (:cardinality_open, :value) => raw"\sum_j d(c_{V_j},O_j)",
        (:cardinality_closed, :value) => raw"\sum_j d(c_{V_j},O_j)+\sum_i[x_i\notin V]",
        (:instantiation, :hamming) => raw"\sum_i[x_i\ne p_i]",
        (:instantiation, :manhattan) => raw"\sum_i\lvert x_i-p_i\rvert",
        (:maximum, :value) => raw"r_{\circ}(\max_i x_i,v)",
        (:minimum, :value) => raw"r_{\circ}(\min_i x_i,v)",
        (:ordered, :adjacent_residual) => raw"\sum_i r_{\circ}(x_i+p_i,x_{i+1})",
        (:increasing, :adjacent_residual) => raw"\sum_i[x_i-x_{i+1}]_+",
        (:decreasing, :adjacent_residual) => raw"\sum_i[x_{i+1}-x_i]_+",
        (:strictly_increasing, :adjacent_residual) => raw"\sum_i r_{<}(x_i,x_{i+1})",
        (:strictly_decreasing, :adjacent_residual) => raw"\sum_i r_{>}(x_i,x_{i+1})",
        (:element, :value) => raw"d_{[1,n]}(k)+r_{\circ}(x_k,v)",
        (:channel, :index_l1) => raw"\begin{cases}\sum_{b,i}\lvert x^{b+1}_{x^b_i}-i\rvert,&\mathrm{dim}\\\sum_i\lvert x_i-[i=k]\rvert,&\mathrm{id}=k\end{cases}",
        (:circuit, :graph_residual) => raw"P_{\mathrm{pred}}(x)+P_{\mathrm{orbit}}(x)+r_{\circ}(\lvert A\rvert,v)",
        (:dist_different, :pair_distance_collision) => raw"[\lvert x_1-x_2\rvert=\lvert x_3-x_4\rvert]",
        (:supports, :hamming) => raw"\min_{t\in S}\sum_i[x_i\ne t_i]",
        (:conflicts, :escape) => raw"[x\in C]",
        (:extension, :grouped_hamming) => raw"\begin{cases}\min_{t\in S}\sum_i[x_i\ne t_i],&S\ \mathrm{only}\\\min(\min_{t\in S}\sum_i[x_i\ne t_i],[x\in C]),&S,C\end{cases}",
        (:regular, :hamming) => raw"d_{L}(x)",
        (:mdd, :hamming) => raw"d_{L}(x)",
        (:no_overlap, :pair_conflicts) => raw"\sum_{i<j}\prod_d[x_{id}+p_{id}>x_{jd}]\,[x_{jd}+p_{jd}>x_{id}]",
        (:no_overlap_no_zero, :pair_conflicts) => raw"\sum_{i<j}[p_i\ne0][p_j\ne0]\,\operatorname{overlap}(i,j)",
        (:no_overlap_with_zero, :pair_conflicts) => raw"\sum_{i<j}\operatorname{overlap}(i,j)",
        (:cumulative, :maximum_event_residual) => raw"\max_k r_{\circ}(u_k,v)",
        (:cumulative, :sum_event_residual) => raw"\sum_k r_{\circ}(u_k,v)",
        (:cumulative, :area_residual) => raw"\sum_k\Delta t_k\,r_{\circ}(u_k,v)",
        (:cumulative, :quadratic_area_residual) => raw"\sum_k\Delta t_k\,r_{\circ}(u_k,v)^2",
    ))
    return nothing
end

function _register_fastest_icn_penalties!()
    merge!(FASTEST_ICN_PENALTIES, Dict(
        :all_different => :pair_conflicts,
        :all_equal => :repair,
        :sum => :value,
        :count => :value,
        :at_least => :value,
        :at_most => :value,
        :exactly => :value,
        :nvalues => :value,
        :cardinality => :value,
        :cardinality_open => :value,
        :cardinality_closed => :value,
        :instantiation => :hamming,
        :maximum => :value,
        :minimum => :value,
        :ordered => :adjacent_residual,
        :increasing => :adjacent_residual,
        :decreasing => :adjacent_residual,
        :strictly_increasing => :adjacent_residual,
        :strictly_decreasing => :adjacent_residual,
        :element => :value,
        :channel => :index_l1,
        :circuit => :graph_residual,
        :dist_different => :pair_distance_collision,
        :supports => :hamming,
        :conflicts => :escape,
        :extension => :grouped_hamming,
        :regular => :hamming,
        :mdd => :hamming,
        :no_overlap => :pair_conflicts,
        :no_overlap_no_zero => :pair_conflicts,
        :no_overlap_with_zero => :pair_conflicts,
        :cumulative => :area_residual,
    ))
    for constraint in (:regular, :mdd)
        haskey(PENALTY_PROFILES[constraint], :hamming) ||
            (FASTEST_ICN_PENALTIES[constraint] = :boolean)
    end
    return nothing
end

_register_reference_formulae!()
_register_fastest_icn_penalties!()

@testitem "Penalty profile registry" tags=[:penalties, :registry] begin
    import Test: @test, @test_throws

    @test penalty_profile(:sum, :value).metric == :manhattan
    @test penalty_profile(:sum, :value).incremental
    @test penalty_profile(:all_different, :repair).incremental
    @test Set(profile.name for profile in penalty_profiles(:all_different)) ==
          Set((:boolean, :repair, :pair_conflicts))
    @test Set(profile.name for profile in penalty_profiles(:cumulative)) ==
          Set((:boolean, :maximum_event_residual, :sum_event_residual,
              :area_residual, :quadratic_area_residual))
    @test all(profile.incremental for profile in penalty_profiles(:cumulative))
    @test Set(keys(PENALTY_PROFILES)) == Set(keys(USUAL_CONSTRAINTS))
    @test Set(keys(FASTEST_ICN_PENALTIES)) == Set(keys(USUAL_CONSTRAINTS))
    @test all(keys(FASTEST_ICN_PENALTIES)) do constraint
        profile = fastest_icn_penalty_profile(constraint)
        profile.exactness === :exact && !isnothing(penalty_formula(profile))
    end
    @test fastest_icn_penalty_f(:sum) === penalty_f(:sum, :value)
    expected_language_profiles = isdefined(Constraints.ConstraintCommons, :language_distance) ?
                                 Set((:boolean, :hamming)) : Set((:boolean,))
    @test Set(profile.name for profile in penalty_profiles(:regular)) ==
          expected_language_profiles
    @test_throws KeyError penalty_profile(:sum, :missing)
    @test_throws ArgumentError register_penalty_profile!(
        :missing, :boolean, identity; metric = :boolean)
    @test_throws ArgumentError register_penalty_profile!(
        :sum, :bad_exactness, identity; metric = :boolean, exactness = :unknown)
end

@testitem "Exact reference penalties" tags=[:penalties, :oracle] begin
    import Test: @test

    function exact_on(concept_f, penalty, assignments; kwargs...)
        for assignment in assignments
            value = penalty(collect(assignment); kwargs...)
            @test isfinite(value)
            @test value >= 0.0
            @test iszero(value) == concept_f(collect(assignment); kwargs...)
        end
    end

    assignments = Iterators.product(ntuple(_ -> 1:3, 4)...)
    exact_on(concept(:all_different), penalty_f(:all_different, :repair), assignments)
    exact_on(concept(:all_different), penalty_f(:all_different, :pair_conflicts), assignments)
    exact_on(concept(:all_equal), penalty_f(:all_equal, :repair), assignments)
    exact_on(concept(:all_equal), penalty_f(:all_equal, :pair_conflicts), assignments)
    exact_on(concept(:sum), penalty_f(:sum, :value), assignments;
        pair_vars = [2, -1, 3, 1], op = <=, val = 7)
    exact_on(concept(:count), penalty_f(:count, :value), assignments;
        vals = [1, 3], op = ==, val = 2)
    exact_on(concept(:nvalues), penalty_f(:nvalues, :value), assignments;
        vals = [3], op = >=, val = 2)
    exact_on(concept(:instantiation), penalty_f(:instantiation, :hamming), assignments;
        pair_vars = [1, 2, 3, 1])
    exact_on(concept(:instantiation), penalty_f(:instantiation, :manhattan), assignments;
        pair_vars = [1, 2, 3, 1])
    exact_on(concept(:maximum), penalty_f(:maximum, :value), assignments;
        op = <=, val = 2)
    exact_on(concept(:minimum), penalty_f(:minimum, :value), assignments;
        op = >=, val = 2)
    exact_on(concept(:ordered), penalty_f(:ordered, :adjacent_residual), assignments;
        op = <=, pair_vars = [1, 0, 1, 0])
    exact_on(concept(:increasing), penalty_f(:increasing, :adjacent_residual), assignments)
    exact_on(concept(:strictly_decreasing),
        penalty_f(:strictly_decreasing, :adjacent_residual), assignments)
    exact_on(concept(:element), penalty_f(:element, :value), assignments;
        id = 2, op = ==, val = 2)

    channel = penalty_f(:channel, :index_l1)
    channel_assignments = Iterators.product(ntuple(_ -> 0:4, 4)...)
    exact_on(concept(:channel), channel, channel_assignments; dim = 1)
    channel_pairs = Iterators.product(ntuple(_ -> 0:2, 4)...)
    exact_on(concept(:channel), channel, channel_pairs; dim = 2)
    indicator_assignments = Iterators.product(ntuple(_ -> 0:1, 4)...)
    exact_on(concept(:channel), channel, indicator_assignments; id = 3)

    circuit = penalty_f(:circuit, :graph_residual)
    for arity in 2:4
        circuit_assignments = Iterators.product(ntuple(_ -> 0:(arity + 1), arity)...)
        exact_on(concept(:circuit), circuit, circuit_assignments)
        circuit_assignments = Iterators.product(ntuple(_ -> 0:(arity + 1), arity)...)
        exact_on(concept(:circuit), circuit, circuit_assignments; op = ==, val = arity)
    end

    tuples = [[1, 2, 3, 1], [3, 2, 1, 3]]
    exact_on(concept(:supports), penalty_f(:supports, :hamming), assignments;
        pair_vars = tuples)
    exact_on(concept(:conflicts), penalty_f(:conflicts, :escape), assignments;
        pair_vars = tuples)
    exact_on(concept(:extension), penalty_f(:extension, :grouped_hamming), assignments;
        pair_vars = tuples)
    exact_on(concept(:extension), penalty_f(:extension, :grouped_hamming), assignments;
        pair_vars = (tuples, [[2, 2, 2, 2], [1, 1, 1, 1]]))

    cardinality_assignments = Iterators.product(ntuple(_ -> 1:4, 4)...)
    vals = [1 1 2; 2 0 2; 3 1 1]
    exact_on(concept(:cardinality), penalty_f(:cardinality, :value),
        cardinality_assignments; bool = false, vals)
    exact_on(concept(:cardinality_closed), penalty_f(:cardinality_closed, :value),
        cardinality_assignments; vals)

    no_overlap_assignments = Iterators.product(ntuple(_ -> 0:3, 4)...)
    lengths = [2, 1, 2, 1]
    exact_on(concept(:no_overlap), penalty_f(:no_overlap, :pair_conflicts),
        no_overlap_assignments; pair_vars = lengths, dim = 1, bool = true)
    box_assignments = Iterators.product(ntuple(_ -> 0:2, 4)...)
    exact_on(concept(:no_overlap), penalty_f(:no_overlap, :pair_conflicts),
        box_assignments; pair_vars = [2, 2, 2, 2], dim = 2, bool = true)

    cumulative_assignments = Iterators.product(ntuple(_ -> 0:3, 3)...)
    task_data = [2 1 2; 2 1 1]
    exact_on(concept(:cumulative), penalty_f(:cumulative, :maximum_event_residual),
        cumulative_assignments; pair_vars = task_data, op = <=, val = 2)
    exact_on(concept(:cumulative), penalty_f(:cumulative, :sum_event_residual),
        cumulative_assignments; pair_vars = task_data, op = <=, val = 2)
    exact_on(concept(:cumulative), penalty_f(:cumulative, :area_residual),
        cumulative_assignments; pair_vars = task_data, op = <=, val = 2)
    exact_on(concept(:cumulative), penalty_f(:cumulative, :quadratic_area_residual),
        cumulative_assignments; pair_vars = task_data, op = <=, val = 2)
    for profile in (
            :maximum_event_residual, :sum_event_residual,
            :area_residual, :quadratic_area_residual)
        exact_on(concept(:cumulative), penalty_f(:cumulative, profile),
            cumulative_assignments; pair_vars = task_data, op = >=, val = 1)
    end

    origins = [0, 1]
    overloaded_tasks = [3 3; 3 3]
    @test penalty_f(:cumulative, :maximum_event_residual)(origins;
        pair_vars = overloaded_tasks, op = <=, val = 4) == 2.0
    @test penalty_f(:cumulative, :sum_event_residual)(origins;
        pair_vars = overloaded_tasks, op = <=, val = 4) == 2.0
    @test penalty_f(:cumulative, :area_residual)(origins;
        pair_vars = overloaded_tasks, op = <=, val = 4) == 4.0
    @test penalty_f(:cumulative, :quadratic_area_residual)(origins;
        pair_vars = overloaded_tasks, op = <=, val = 4) == 8.0
end

@testitem "Exact language penalties" tags=[:penalties, :oracle, :language] begin
    import ConstraintCommons
    import Test: @test

    if isdefined(ConstraintCommons, :language_distance)
        automaton = ConstraintCommons.Automaton(
            Dict(
                (:start, 0) => :start,
                (:start, 1) => :finish,
                (:finish, 1) => :finish
            ),
            :start, :finish)
        regular_concept = concept(:regular)
        regular_penalty = penalty_f(:regular, :hamming)
        workspace = ConstraintCommons.language_distance_workspace(automaton)
        for word in Iterators.product(ntuple(_ -> (0, 1), 4)...)
            values = collect(word)
            @test iszero(regular_penalty(values; language = automaton)) ==
                  regular_concept(values; language = automaton)
            @test regular_penalty(values; language=automaton, X=zeros(2,2)) ==
                  regular_penalty(values; language=automaton, X=workspace)
        end

        diagram = ConstraintCommons.MDD([
            Dict((:root, 0) => :left, (:root, 1) => :right),
            Dict((:left, 1) => :terminal, (:right, 0) => :terminal)
        ])
        mdd_concept = concept(:mdd)
        mdd_penalty = penalty_f(:mdd, :hamming)
        workspace = ConstraintCommons.language_distance_workspace(diagram)
        for word in Iterators.product((0, 1), (0, 1))
            values = collect(word)
            @test iszero(mdd_penalty(values; language = diagram)) ==
                  mdd_concept(values; language = diagram)
            @test mdd_penalty(values; language=diagram, X=zeros(2,2)) ==
                  mdd_penalty(values; language=diagram, X=workspace)
        end
    else
        @test Set(profile.name for profile in penalty_profiles(:regular)) ==
              Set((:boolean,))
    end
end

@testitem "Incremental reference penalties" tags=[:penalties, :invariant] begin
    import Test: @inferred, @test

    sum_error = bind_error(penalty_f(:sum, :value);
        pair_vars = [2, -1, 3, 1], op = ==, val = 8)
    all_different_errors = (
        penalty_f(:all_different, :repair),
        penalty_f(:all_different, :pair_conflicts)
    )
    assignments = Iterators.product(ntuple(_ -> 1:3, 4)...)
    for assignment in assignments
        values = collect(assignment)
        sum_invariant = initialize_invariant(sum_error, values)
        @test @inferred(invariant_value(sum_invariant)) == sum_error(values)
        for position in eachindex(values), replacement in 1:3

            change = InvariantChange(position, values[position], replacement)
            candidate = copy(values)
            candidate[position] = replacement
            @test candidate_value(sum_invariant, change) == sum_error(candidate)
            @test invariant_value(sum_invariant) == sum_error(values)
        end

        for error in all_different_errors
            invariant = initialize_invariant(error, values)
            @test invariant_value(invariant) == error(values)
            for position in eachindex(values), replacement in 1:3

                change = InvariantChange(position, values[position], replacement)
                candidate = copy(values)
                candidate[position] = replacement
                @test candidate_value(invariant, change) == error(candidate)
                @test invariant_value(invariant) == error(values)
            end
        end
    end

    task_data = [3 2 4 1; 2 3 1 2]
    origins = [0, 1, 2, 4]
    cumulative_errors = Tuple(bind_error(penalty_f(:cumulative, profile);
        pair_vars = task_data, op = <=, val = 3) for profile in
        (:maximum_event_residual, :sum_event_residual,
         :area_residual, :quadratic_area_residual))
    for error in cumulative_errors
        invariant = initialize_invariant(error, origins)
        @test supports_incremental(invariant)
        @test invariant_value(invariant) == error(origins)
        changes = (
            InvariantChange(1, origins[1], 3),
            InvariantChange(4, origins[4], 0),
        )
        candidate = copy(origins)
        candidate[1] = 3
        candidate[4] = 0
        @test candidate_value(invariant, changes) == error(candidate)
        @test invariant_value(invariant) == error(origins)
        @test commit_changes!(invariant, changes) == error(candidate)
        @test rollback_changes!(invariant, changes) == error(origins)
    end

    function cumulative_candidate_allocations(invariant, changes)
        candidate_value(invariant, changes)
        return @allocated candidate_value(invariant, changes)
    end
    allocation_error = first(cumulative_errors)
    allocation_invariant = initialize_invariant(allocation_error, origins)
    allocation_change = InvariantChange(2, origins[2], 5)
    @test cumulative_candidate_allocations(allocation_invariant, allocation_change) == 0
end
