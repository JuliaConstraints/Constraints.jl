"""
    AbstractInvariant

State owned by one constraint evaluation unit. Incremental implementations may specialize the
protocol below; `FunctionalInvariant` preserves support for every existing constraint by
recomputing its error from solver-independent local values.
"""
abstract type AbstractInvariant end

supports_incremental(::AbstractInvariant) = true
supports_incremental(::Function) = false

"""A change at a position local to a constraint's ordered variable list."""
struct InvariantChange{T}
    position::Int
    old_value::T
    new_value::T
end

"""A constraint error function with parameters fixed before the search starts."""
struct BoundError{F <: Function, P <: NamedTuple} <: Function
    error::F
    parameters::P
end

function bind_error(error::F; parameters...) where {F <: Function}
    BoundError(error, (; parameters...))
end

supports_incremental(error::BoundError) = supports_incremental(error.error)

function _unit_concept_error(error::ConceptPenalty{S, F}) where {S, F}
    return ConceptError{S, F}(error.concept)
end

function supports_incremental(error::ConceptPenalty)
    supports_incremental(_unit_concept_error(error))
end

function (error::BoundError)(values; X = nothing)
    return _evaluate_error(error.error, values, X, error.parameters)
end

_evaluate_error(error, values, ::Nothing, parameters) = error(values; parameters...)
_evaluate_error(error, values, X, parameters) = error(values; X, parameters...)

mutable struct FunctionalInvariant{F, P, V <: AbstractVector, X} <: AbstractInvariant
    error::F
    parameters::P
    values::V
    external::X
    current::Float64
end

function _functional_invariant(error, values, X, parameters)
    local_values = collect(values)
    current = Float64(_evaluate_error(error, local_values, X, parameters))
    return FunctionalInvariant(error, parameters, local_values, X, current)
end

function initialize_invariant(error::F, values; X = nothing, parameters...) where {F <:
                                                                                   Function}
    params = (; parameters...)
    return _functional_invariant(error, values, X, params)
end

function initialize_invariant(error::BoundError, values; X = nothing)
    return initialize_invariant(error.error, values; X, error.parameters...)
end

invariant_value(invariant::FunctionalInvariant) = invariant.current
supports_incremental(::FunctionalInvariant) = false

@inline function _apply_change!(values, change::InvariantChange)
    values[change.position] = change.new_value
    return nothing
end

@inline function _revert_change!(values, change::InvariantChange)
    values[change.position] = change.old_value
    return nothing
end

function candidate_value(invariant::FunctionalInvariant, changes::Union{
        Tuple, AbstractVector})
    foreach(change -> _apply_change!(invariant.values, change), changes)
    try
        return Float64(_evaluate_error(
            invariant.error, invariant.values, invariant.external, invariant.parameters))
    finally
        foreach(change -> _revert_change!(invariant.values, change), Iterators.reverse(changes))
    end
end

function candidate_value(invariant::AbstractInvariant, change::InvariantChange)
    candidate_value(invariant, (change,))
end

function commit_changes!(invariant::FunctionalInvariant, changes::Union{
        Tuple, AbstractVector})
    foreach(change -> _apply_change!(invariant.values, change), changes)
    invariant.current = Float64(_evaluate_error(
        invariant.error, invariant.values, invariant.external, invariant.parameters))
    return invariant.current
end

function commit_changes!(invariant::AbstractInvariant, change::InvariantChange)
    commit_changes!(invariant, (change,))
end

function rollback_changes!(invariant::FunctionalInvariant, changes::Union{
        Tuple, AbstractVector})
    foreach(change -> _revert_change!(invariant.values, change), Iterators.reverse(changes))
    invariant.current = Float64(_evaluate_error(
        invariant.error, invariant.values, invariant.external, invariant.parameters))
    return invariant.current
end

function rollback_changes!(invariant::AbstractInvariant, change::InvariantChange)
    rollback_changes!(invariant, (change,))
end

function rebuild_invariant!(invariant::FunctionalInvariant, values)
    resize!(invariant.values, length(values))
    copyto!(invariant.values, values)
    invariant.current = Float64(_evaluate_error(
        invariant.error, invariant.values, invariant.external, invariant.parameters))
    return invariant.current
end

function synchronize_invariant!(invariant::FunctionalInvariant, values, current)
    resize!(invariant.values, length(values))
    copyto!(invariant.values, values)
    invariant.current = Float64(current)
    return invariant.current
end

function synchronize_invariant!(invariant::AbstractInvariant, values, current)
    return rebuild_invariant!(invariant, values)
end

"""An invariant whose exact binary violation is multiplied by a fixed positive penalty."""
mutable struct PenalizedInvariant{I <: AbstractInvariant, P <: Real} <: AbstractInvariant
    invariant::I
    penalty::P
end

function initialize_invariant(error::ConceptPenalty, values; X = nothing, parameters...)
    invariant = initialize_invariant(
        _unit_concept_error(error), values; X, parameters...)
    return PenalizedInvariant(invariant, error.penalty)
end

function supports_incremental(invariant::PenalizedInvariant)
    supports_incremental(invariant.invariant)
end

@inline _penalize(invariant::PenalizedInvariant, value) = Float64(invariant.penalty) * value

function invariant_value(invariant::PenalizedInvariant)
    _penalize(invariant, invariant_value(invariant.invariant))
end

function candidate_value(invariant::PenalizedInvariant, changes::Union{
        Tuple, AbstractVector})
    return _penalize(invariant, candidate_value(invariant.invariant, changes))
end

function commit_changes!(invariant::PenalizedInvariant, changes::Union{
        Tuple, AbstractVector})
    return _penalize(invariant, commit_changes!(invariant.invariant, changes))
end

function rollback_changes!(invariant::PenalizedInvariant, changes::Union{
        Tuple, AbstractVector})
    return _penalize(invariant, rollback_changes!(invariant.invariant, changes))
end

function rebuild_invariant!(invariant::PenalizedInvariant, values)
    return _penalize(invariant, rebuild_invariant!(invariant.invariant, values))
end

function synchronize_invariant!(invariant::PenalizedInvariant, values, current)
    synchronize_invariant!(
        invariant.invariant, values, current / Float64(invariant.penalty))
    return Float64(current)
end

if isdefined(CompositionalNetworks, :IncrementalCompositionState)
    const _ICNComposition = if isdefined(
        CompositionalNetworks, :AbstractIncrementalComposition)
        CompositionalNetworks.AbstractIncrementalComposition
    else
        CompositionalNetworks.IncrementalComposition
    end
    const _ICNCompositionState = if isdefined(
        CompositionalNetworks, :AbstractIncrementalCompositionState)
        CompositionalNetworks.AbstractIncrementalCompositionState
    else
        CompositionalNetworks.IncrementalCompositionState
    end

    """
        ICNInvariant

    Adapter between the generic constraint-invariant protocol and a composition whose primitive
    operations support incremental updates. Each constraint instance owns its ICN state and
    buffers; the learned composition itself remains shareable and immutable.
    """
    mutable struct ICNInvariant{S <: _ICNCompositionState} <: AbstractInvariant
        state::S
    end

    supports_incremental(::_ICNComposition) = true

    function initialize_invariant(
            error::_ICNComposition, values;
            X = nothing, parameters...)
        abstract_workspace = isdefined(CompositionalNetworks, :AbstractIncrementalWorkspace)
        supplied_workspace = (abstract_workspace &&
                              X isa CompositionalNetworks.AbstractIncrementalWorkspace) ||
                             X isa CompositionalNetworks.IncrementalWorkspace
        state = if supplied_workspace
            CompositionalNetworks.incremental_state(
                error, values; workspace = X, parameters...)
        else
            CompositionalNetworks.incremental_state(error, values; parameters...)
        end
        return ICNInvariant(state)
    end

    function invariant_value(invariant::ICNInvariant)
        CompositionalNetworks.incremental_value(invariant.state)
    end

    if isdefined(CompositionalNetworks, :incremental_candidate_value!)
        function candidate_value(
                invariant::ICNInvariant, changes::Union{Tuple, AbstractVector})
            return CompositionalNetworks.incremental_candidate_value!(
                invariant.state, changes)
        end
    else
        function candidate_value(
                invariant::ICNInvariant, changes::Union{Tuple, AbstractVector})
            applied = 0
            try
                for change in changes
                    CompositionalNetworks.incremental_update!(
                        invariant.state, change.position, change.new_value)
                    applied += 1
                end
                return invariant_value(invariant)
            finally
                for index in applied:-1:1
                    change = changes[index]
                    CompositionalNetworks.incremental_update!(
                        invariant.state, change.position, change.old_value)
                end
            end
        end
    end

    function commit_changes!(invariant::ICNInvariant, changes::Union{Tuple, AbstractVector})
        for change in changes
            CompositionalNetworks.incremental_update!(
                invariant.state, change.position, change.new_value)
        end
        return invariant_value(invariant)
    end

    function rollback_changes!(invariant::ICNInvariant, changes::Union{
            Tuple, AbstractVector})
        for change in Iterators.reverse(changes)
            CompositionalNetworks.incremental_update!(
                invariant.state, change.position, change.old_value)
        end
        return invariant_value(invariant)
    end

    function rebuild_invariant!(invariant::ICNInvariant, values)
        return CompositionalNetworks.incremental_rebuild!(invariant.state, values)
    end
end

@testitem "Generic invariant fallback" tags=[:constraint, :invariant] begin
    import Test: @test

    error = (values; target) -> Float64(abs(sum(values) - target))
    invariant = initialize_invariant(bind_error(error; target = 6), [1, 2, 3])
    changes = (InvariantChange(1, 1, 4), InvariantChange(3, 3, 1))

    @test invariant_value(invariant) == 0.0
    @test candidate_value(invariant, changes) == 1.0
    @test invariant_value(invariant) == 0.0
    @test commit_changes!(invariant, changes) == 1.0
    @test rollback_changes!(invariant, changes) == 0.0
    @test rebuild_invariant!(invariant, [2, 2, 2]) == 0.0
    @test synchronize_invariant!(invariant, [4, 1, 1], 0.0) == 0.0
    @test candidate_value(invariant, InvariantChange(1, 4, 1)) == 3.0
end

@testitem "Incremental learned composition adapter" default_imports=false begin
    import CompositionalNetworks as CN
    import Constraints as C
    import Test: @inferred, @test

    if isdefined(CN, :incremental_composition)
        function select!(network, operations)
            fill!(network.weights.parent, false)
            offset = 0
            for (layer, selected) in zip(network.layers, operations)
                names = collect(keys(layer.fn))
                for operation in selected
                    network.weights.parent[offset + only(findall(==(operation), names))] = true
                end
                offset += length(layer.fn)
            end
            return network
        end

        network = select!(CN.ICN(), (
            (:count_equal_left,), (:sum,), (:count_positive,), (:id,)))
        learned = CN.incremental_composition(network)
        invariant = C.initialize_invariant(learned, [1, 2, 3, 4])
        duplicate = C.InvariantChange(4, 4, 2)

        @test C.supports_incremental(learned)
        @test @inferred(C.invariant_value(invariant)) == 0.0
        @test @inferred(C.candidate_value(invariant, duplicate)) == 1.0
        @test C.invariant_value(invariant) == 0.0
        @test C.commit_changes!(invariant, duplicate) == 1.0
        @test C.rollback_changes!(invariant, duplicate) == 0.0

        swap = (C.InvariantChange(1, 1, 2), C.InvariantChange(2, 2, 1))
        @test C.candidate_value(invariant, swap) == 0.0
        @test C.invariant_value(invariant) == 0.0

        for assignment in Iterators.product(ntuple(_ -> 1:3, 4)...)
            values = collect(assignment)
            trial = C.initialize_invariant(learned, values)
            for depth in 0:length(values)
                changes = C.InvariantChange{Int}[C.InvariantChange(
                                                     position, values[position],
                                                     mod1(position + 1, 3))
                                                 for position in 1:depth]
                candidate = copy(values)
                for change in changes
                    candidate[change.position] = change.new_value
                end
                @test C.candidate_value(trial, changes) == learned(candidate)
                @test C.invariant_value(trial) == learned(values)
            end
        end

        workspace = CN.incremental_workspace(learned, [1, 1, 3, 4])
        owned = C.initialize_invariant(learned, [1, 1, 3, 4]; X = workspace)
        @test owned.state.workspace === workspace
        @test C.rebuild_invariant!(owned, [1, 2, 3, 4]) == 0.0

        sum_network = select!(CN.ICN(parameters = [:val]), (
            (:id,), (:sum,), (:sum,), (:abs_val,)))
        learned_sum = CN.incremental_composition(sum_network)
        sum_workspace = CN.incremental_workspace(learned_sum, [1, 2, 3, 4])
        sum_invariant = C.initialize_invariant(
            C.bind_error(learned_sum; val = 11), [1, 2, 3, 4]; X = sum_workspace)
        @test sum_invariant.state.workspace === sum_workspace
        @test @inferred(C.invariant_value(sum_invariant)) == 1.0
        @test @inferred(C.candidate_value(
            sum_invariant, C.InvariantChange(1, 1, 2))) == 0.0
        @test C.invariant_value(sum_invariant) == 1.0

        for assignment in Iterators.product(ntuple(_ -> 0:3, 4)...)
            values = collect(assignment)
            trial = C.initialize_invariant(C.bind_error(learned_sum; val = 5), values)
            for depth in 0:length(values)
                changes = C.InvariantChange{Int}[C.InvariantChange(
                                                     position, values[position],
                                                     mod(values[position] + 1, 4))
                                                 for position in 1:depth]
                candidate = copy(values)
                for change in changes
                    candidate[change.position] = change.new_value
                end
                @test C.candidate_value(trial, changes) == learned_sum(candidate; val = 5)
                @test C.invariant_value(trial) == learned_sum(values; val = 5)
            end
        end

        if isdefined(CN, :PairwiseDisjunctionCompositionState)
            pairwise_network = select!(CN.ICN(
                parameters = [:pair_vars, :dim, :bool, :numvars, :dom_size],
                layers = [CN.PairedMap, CN.PairMask, CN.GroupReduction, CN.Transformation, CN.Arithmetic,
                    CN.Aggregation, CN.Comparison],
                connection = UInt32.(1:7),
            ), (
                (:pairwise_oriented_affine_margins,), (:zero_extent_groups,), (:minimum,), (:positive_part,),
                (:sum,), (:sum,), (:id,),
            ))
            pairwise = CN.incremental_composition(pairwise_network)
            pairwise_parameters = (;
                pair_vars = [2, 2, 1], dim = 1, bool = true,
                numvars = 3, dom_size = 5,
            )
            pairwise_invariant = C.initialize_invariant(
                C.bind_error(pairwise; pairwise_parameters...), [0, 1, 4])
            pairwise_change = C.InvariantChange(2, 1, 3)
            @test C.supports_incremental(pairwise)
            @test C.candidate_value(pairwise_invariant, pairwise_change) ==
                  pairwise([0, 3, 4]; pairwise_parameters...)
            @test C.invariant_value(pairwise_invariant) ==
                  pairwise([0, 1, 4]; pairwise_parameters...)
            pairwise_batch = (
                C.InvariantChange(1, 0, 3),
                C.InvariantChange(2, 1, 0),
            )
            @test C.candidate_value(pairwise_invariant, pairwise_batch) ==
                  pairwise([3, 0, 4]; pairwise_parameters...)
            @test C.invariant_value(pairwise_invariant) ==
                  pairwise([0, 1, 4]; pairwise_parameters...)
        end

        if isdefined(CN, :EventProfileCompositionState)
            event_network = select!(CN.ICN(
                parameters = [:pair_vars, :op, :val, :numvars, :dom_size],
                layers = [CN.EventMap, CN.SegmentMap, CN.Arithmetic,
                    CN.Aggregation, CN.Comparison],
                connection = UInt32.(1:5),
            ), (
                (:weighted_interval_segments,), (:loads,), (:sum,), (:maximum,),
                (:var_minus_val,),
            ))
            event = CN.incremental_composition(event_network)
            event_parameters = (;
                pair_vars = [2 2 1; 2 1 2], op = (<=), val = 3,
                numvars = 3, dom_size = 5,
            )
            event_invariant = C.initialize_invariant(
                C.bind_error(event; event_parameters...), [0, 1, 3])
            @test C.supports_incremental(event)
            @test C.invariant_value(event_invariant) == 0.0
            event_changes = (
                C.InvariantChange(2, 1, 0),
                C.InvariantChange(3, 3, 0),
            )
            @test C.candidate_value(event_invariant, event_changes) ==
                  event([0, 0, 0]; event_parameters...) == 2.0
            @test C.invariant_value(event_invariant) ==
                  event([0, 1, 3]; event_parameters...) == 0.0

            # Area is now expressed with atomic segment projections and product,
            # not the removed composite segment_condition_area operation.
            for operator in ((<=), (==))
                area_parameters = merge(event_parameters, (; op = operator))
                area_network = select!(CN.ICN(
                    parameters = [:pair_vars, :op, :val, :numvars, :dom_size],
                    layers = [CN.EventMap, CN.SegmentMap, CN.Arithmetic,
                        CN.Aggregation, CN.Comparison],
                    connection = UInt32.(1:5),
                ), (
                    (:weighted_interval_segments,), (:widths, :condition_residuals),
                    (:product,), (:sum,), (:id,),
                ))
                area = CN.incremental_composition(area_network)
                area_invariant = C.initialize_invariant(
                    C.bind_error(area; area_parameters...), [0, 1, 3])
                initial = area([0, 1, 3]; area_parameters...)
                candidate = area([0, 0, 0]; area_parameters...)
                @test C.supports_incremental(area)
                @test C.invariant_value(area_invariant) == initial
                @test C.candidate_value(area_invariant, event_changes) == candidate
                @test C.invariant_value(area_invariant) == initial
                @test C.commit_changes!(area_invariant, event_changes) == candidate
                @test C.rollback_changes!(area_invariant, event_changes) == initial
                @test C.rebuild_invariant!(area_invariant, [0, 0, 0]) == candidate
            end
        end
    else
        @test true
    end
end
