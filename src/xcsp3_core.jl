# Solver-independent XCSP3 structural semantics. This file does not add ICN
# operations or learn constraint-specific primitives. Missing graded penalties
# use the explicit Boolean fallback, never a claim of search-quality parity.

core_operator(::Val{:eq}) = ==
core_operator(::Val{:ne}) = !=
core_operator(::Val{:lt}) = <
core_operator(::Val{:le}) = <=
core_operator(::Val{:gt}) = >
core_operator(::Val{:ge}) = >=
core_operator(::Val{:in}) = in
core_operator(::Val{:notin}) = (x, y) -> x ∉ y
core_operator(op::Symbol) = core_operator(Val(op))
core_condition(value, condition) = core_operator(condition[1])(value, condition[2])
core_condition(value, ::Nothing) = true

function core_expression(op::Symbol, args::Tuple)
    op == :neg && return -args[1]
    op == :abs && return abs(args[1])
    op == :sqr && return args[1]^2
    op == :add && return sum(args)
    op == :sub && return args[1] - args[2]
    op == :mul && return prod(args)
    op == :div && return div(args[1], args[2])
    op == :mod && return rem(args[1], args[2])
    op == :pow && return args[1]^args[2]
    op == :min && return minimum(args)
    op == :max && return maximum(args)
    op == :dist && return abs(args[1] - args[2])
    op == :set && return args
    op == :eq && return all(==(args[1]), args)
    op == :not && return !Bool(args[1])
    op == :and && return all(Bool, args)
    op == :or && return any(Bool, args)
    op == :xor && return isodd(count(Bool, args))
    op == :iff && return all(==(Bool(args[1])), Bool.(args))
    op == :imp && return !Bool(args[1]) || Bool(args[2])
    op == :if && return Bool(args[1]) ? args[2] : args[3]
    return core_operator(op)(args...)
end

function _core_index(value, start, length)
    value isa Real && isfinite(value) && isinteger(value) || return 0
    start <= value < start + length || return 0
    return Int(value - start + 1)
end

function _core_rank(list, index, predicate, rank)
    1 <= index <= length(list) || return false
    predicate(list[index]) || return false
    rank == :first && return !any(predicate, @view list[1:(index - 1)])
    rank == :last && return !any(predicate, @view list[(index + 1):end])
    return true
end

core_satisfied(::Val{:intension}, a) = Bool(a.expression)
function core_satisfied(::Val{:all_equal}, a)
    values = filter(!in(get(a,:except,())),a.list)
    return isempty(values) || all(==(first(values)),values)
end

@testitem "Core allEqual exceptions are not discarded" default_imports=false begin
    using Test
    import Constraints as C
    @test C.core_satisfied(Val(:all_equal),(;list=[0,1,1],except=[0]))
    @test !C.core_satisfied(Val(:all_equal),(;list=[0,1,2],except=[0]))
    @test C.core_satisfied(Val(:all_equal),(;list=[0,0,0],except=[0]))
    @test C.core_satisfied(Val(:all_equal),(;list=Int[],except=[0]))
    @test !C.core_satisfied(Val(:all_equal),(;list=[0,1,1]))
    evaluator=C.CoreEvaluator(Val(:all_equal))
    @test iszero(evaluator((;list=[0,1,1],except=[0])))
    @test !iszero(evaluator((;list=[0,1,2],except=[0])))
end
function core_satisfied(::Val{:extension}, a)
    matched = any(a.tuples) do tuple
        length(tuple) == length(a.list) || throw(DimensionMismatch("table tuple arity"))
        all(eachindex(a.list)) do i
            cell = tuple[i]
            cell === nothing || cell == a.list[i]
        end
    end
    return matched == get(a, :positive, true)
end

"""Immutable transition index shared by evaluations; NFA working sets remain call-local."""
struct CoreLanguage{D,S,F}
    transitions::D
    start::S
    final::F
    deterministic::Bool
end
function CoreLanguage(transitions; start = nothing, final = nothing)
    sources = Set(first(edge) for edge in transitions)
    destinations = Set(last(edge) for edge in transitions)
    if isnothing(start)
        roots = setdiff(sources, destinations)
        length(roots) == 1 || throw(ArgumentError("MDD must have one root or an explicit start"))
        start = only(roots)
    end
    final = isnothing(final) ? setdiff(destinations, sources) : Set(final)
    table = Dict{Tuple{Any,Any},Vector{Any}}()
    for (source,symbol,destination) in transitions
        following = get!(() -> Any[], table, (source,symbol))
        destination in following || push!(following,destination)
    end
    return CoreLanguage(table,start,final,all(v -> length(v)==1,values(table)))
end
function _core_accept(language::CoreLanguage, word)
    if language.deterministic
        current = language.start
        for label in word
            following = get(language.transitions,(current,label),nothing)
            isnothing(following) && return false
            current = only(following)
        end
        return current in language.final
    end
    active, following = Set{Any}([language.start]), Set{Any}()
    for label in word
        empty!(following)
        for current in active
            destinations = get(language.transitions,(current,label),nothing)
            isnothing(destinations) || union!(following,destinations)
        end
        isempty(following) && return false
        active, following = following, active
    end
    return any(v -> v in language.final, active)
end
function _core_accept(a)
    a.transitions isa CoreLanguage && return _core_accept(a.transitions,a.list)
    transitions = a.transitions
    sources = Set(first(edge) for edge in transitions)
    destinations = Set(last(edge) for edge in transitions)
    start = get(a, :start, nothing)
    if isnothing(start)
        roots = setdiff(sources, destinations)
        length(roots) == 1 || throw(ArgumentError("MDD must have one root or an explicit start"))
        start = only(roots)
    end
    final = get(a, :final, setdiff(destinations, sources))
    active = Set([start])
    for label in a.list
        following = empty(active)
        for (source, symbol, destination) in transitions
            source in active && symbol == label && push!(following, destination)
        end
        isempty(following) && return false
        active = following
    end
    return any(state -> state in final, active)
end
core_satisfied(::Val{:regular}, a) = _core_accept(a)
core_satisfied(::Val{:mdd}, a) = _core_accept(a)

function core_satisfied(::Val{:sum}, a)
    if !haskey(a, :coefficients)
        return core_condition(sum(a.list), a.condition)
    end
    length(a.list) == length(a.coefficients) || throw(DimensionMismatch("sum coefficients"))
    return core_condition(sum((a.list[i] * a.coefficients[i] for i in eachindex(a.list)); init = 0), a.condition)
end
core_satisfied(::Val{:count}, a) = core_condition(count(v -> v in a.values, a.list), a.condition)
core_satisfied(::Val{:nvalues}, a) = core_condition(length(Set(v for v in a.list if v ∉ get(a,:except,()))), a.condition)

function core_satisfied(::Val{:all_different}, a)
    if haskey(a, :list)
        except = get(a, :except, ())
        return all(a.list[i] in except || a.list[i] != a.list[j]
            for i in eachindex(a.list) for j in (i+1):length(a.list))
    end
    if haskey(a, :matrix)
        except = get(a, :except, ())
        distinct(row) = length(Set(v for v in row if v ∉ except)) == count(v -> v ∉ except, row)
        return all(distinct, eachrow(a.matrix)) && all(distinct, eachcol(a.matrix))
    end
    lists = a.lists
    except = get(a, :except, ())
    return all(lists[i] in except || lists[i] != lists[j] for i in eachindex(lists) for j in (i + 1):length(lists))
end
function core_satisfied(::Val{:ordered}, a)
    x = a.list
    lengths = get(a, :lengths, nothing)
    isnothing(lengths) || length(lengths) in (length(x) - 1, length(x)) ||
        throw(DimensionMismatch("ordered lengths"))
    op = core_operator(get(a, :operator, :le))
    return all(i -> op(x[i] + (isnothing(lengths) ? 0 : lengths[i]), x[i + 1]), 1:(length(x) - 1))
end
function _core_lex(left, right, op)
    length(left) == length(right) || throw(DimensionMismatch("lex list lengths"))
    for i in eachindex(left)
        left[i] == right[i] && continue
        return core_operator(op)(left[i], right[i])
    end
    return op in (:le, :ge)
end
function core_satisfied(::Val{:lex}, a)
    op = get(a, :operator, :le)
    if haskey(a, :matrix)
        rows, columns = collect(eachrow(a.matrix)), collect(eachcol(a.matrix))
        return all(i -> _core_lex(rows[i], rows[i + 1], op), 1:(length(rows) - 1)) &&
               all(i -> _core_lex(columns[i], columns[i + 1], op), 1:(length(columns) - 1))
    end
    return all(i -> _core_lex(a.lists[i], a.lists[i + 1], op), 1:(length(a.lists) - 1))
end
"""Prepare implicit precedence values from model domains, outside candidate evaluation."""
core_precedence_values(domains) = sort!(unique!(collect(Iterators.flatten(domains))))

@testitem "Core precedence implicit values require domain metadata" default_imports=false begin
    using Test
    import Constraints as C
    @test C.core_precedence_values(([0, 2], [1, 2])) == [0, 1, 2]
    @test !C.core_satisfied(Val(:precedence), (; list = [2, 2, 2], domains = [0:2, 0:2, 0:2]))
    @test C.core_satisfied(Val(:precedence), (; list = [0, 1, 2], domains = [0:2, 0:2, 0:2]))
    @test C.core_satisfied(Val(:precedence), (; list = [2, 2], values = [2]))
    @test !C.core_satisfied(Val(:precedence), (; list = [0, 0], values = [0, 1], covered = true))
    @test_throws ArgumentError C.core_satisfied(Val(:precedence), (; list = [2, 2]))
end

function core_satisfied(::Val{:precedence}, a)
    values = if haskey(a, :values)
        a.values
    elseif haskey(a, :domains)
        core_precedence_values(a.domains)
    else
        throw(ArgumentError("implicit precedence requires the original scope domains or explicit values"))
    end
    previous = 0
    for value in values
        index = findfirst(==(value), a.list)
        if isnothing(index)
            get(a, :covered, false) && return false
            previous = typemax(Int)
        else
            index > previous || return false
            previous = index
        end
    end
    return true
end
function _core_extremum(a, operation)
    isempty(a.list) && return false
    value = operation(a.list)
    core_condition(value, get(a, :condition, nothing)) || return false
    haskey(a, :index) || return true
    index = _core_index(a.index, get(a, :start_index, 1), length(a.list))
    return _core_rank(a.list, index, ==(value), get(a, :rank, :any))
end
core_satisfied(::Val{:minimum}, a) = _core_extremum(a, minimum)
core_satisfied(::Val{:maximum}, a) = _core_extremum(a, maximum)
function core_satisfied(::Val{:element}, a)
    condition = get(a, :condition, nothing)
    predicate = isnothing(condition) ? ==(a.value) : x -> core_condition(x, condition)
    if haskey(a, :matrix)
        row = _core_index(a.row_index, get(a, :row_start, 1), size(a.matrix, 1))
        col = _core_index(a.column_index, get(a, :column_start, 1), size(a.matrix, 2))
        return !iszero(row) && !iszero(col) && predicate(a.matrix[row, col])
    end
    haskey(a, :index) || return any(predicate, a.list)
    index = _core_index(a.index, get(a, :start_index, 1), length(a.list))
    return _core_rank(a.list, index, predicate, get(a, :rank, :any))
end
function core_satisfied(::Val{:channel}, a)
    x, start = a.list, get(a, :start_index, 1)
    if haskey(a, :value)
        index = _core_index(a.value, start, length(x))
        return index != 0 && all(i -> x[i] == (i == index), eachindex(x))
    end
    y, second_start = get(a, :second, x), get(a, :second_start, start)
    length(x) <= length(y) || throw(DimensionMismatch("first channel list must not be longer than second"))
    for i in eachindex(x)
        j = _core_index(x[i], second_start, length(y))
        j != 0 && y[j] == i + start - 1 || return false
    end
    if length(x) == length(y)
        for j in eachindex(y)
            i = _core_index(y[j], start, length(x))
            i != 0 && x[i] == j + second_start - 1 || return false
        end
    end
    return true
end
function core_satisfied(::Val{:stretch}, a)
    x = a.list
    length(a.values) == length(a.widths) || throw(DimensionMismatch("stretch widths"))
    i = 1
    while i <= length(x)
        j = i + 1
        while j <= length(x) && x[j] == x[i]; j += 1; end
        key = findfirst(==(x[i]), a.values)
        isnothing(key) && return false
        (j - i) in a.widths[key] || return false
        if j <= length(x) && haskey(a, :patterns)
            (x[i], x[j]) in a.patterns || return false
        end
        i = j
    end
    return true
end
function core_satisfied(::Val{:no_overlap}, a)
    x, lengths = a.origins, a.lengths
    dimension = get(a, :dim, x isa AbstractMatrix ? size(x, 1) : 1)
    size(x) == size(lengths) || throw(DimensionMismatch("noOverlap origins/lengths"))
    all(>=(0), lengths) || return false
    return concept_no_overlap(vec(x); pair_vars = vec(lengths), dim = dimension,
        bool = get(a, :zero_ignored, true))
end
function core_satisfied(::Val{:cumulative}, a)
    all(>=(0), a.lengths) && all(>=(0), a.heights) || return false
    if haskey(a, :ends)
        length(a.ends) == length(a.origins) || throw(DimensionMismatch("cumulative ends"))
        all(i -> a.origins[i] + a.lengths[i] == a.ends[i], eachindex(a.ends)) || return false
    end
    condition = a.condition
    return xcsp_cumulative(; origins = a.origins, lengths = a.lengths,
        heights = a.heights, condition = (core_operator(condition[1]), condition[2]))
end
function core_satisfied(::Val{:bin_packing}, a)
    x, sizes = a.list, a.sizes
    length(x) == length(sizes) || throw(DimensionMismatch("bin packing sizes"))
    all(>=(0), sizes) || return false
    all(v -> v isa Real && isfinite(v) && isinteger(v), x) || return false
    if haskey(a, :condition)
        return all(Set(x)) do bin
            load = sum((sizes[i] for i in eachindex(x) if x[i] == bin); init = 0)
            core_condition(load, a.condition)
        end
    end
    targets = haskey(a, :loads) ? a.loads : a.conditions
    start = get(a, :start_index, 1)
    all(bin -> start <= bin < start + length(targets), x) || return false
    return all(eachindex(targets)) do j
        load = sum((sizes[i] for i in eachindex(x) if x[i] == j + start - 1); init = 0)
        haskey(a, :loads) ? load == targets[j] : core_condition(load, targets[j])
    end
end
function core_satisfied(::Val{:knapsack}, a)
    length(a.list) == length(a.weights) == length(a.profits) || throw(DimensionMismatch("knapsack data"))
    return core_condition(sum((a.list[i] * a.weights[i] for i in eachindex(a.list)); init = 0), a.weight_condition) &&
        core_condition(sum((a.list[i] * a.profits[i] for i in eachindex(a.list)); init = 0), a.profit_condition)
end
core_satisfied(::Val{:instantiation}, a) = length(a.list) == length(a.values) && all(i -> a.list[i] == a.values[i], eachindex(a.list))
function core_satisfied(::Val{:circuit}, a)
    start = get(a, :start_index, 1)
    normalized = [_core_index(value, start, length(a.list)) for value in a.list]
    size = _subcircuit_size(normalized)
    return !isnothing(size) && (!haskey(a, :size) || size == a.size)
end

# A compiled slide template is a callable zero-set evaluator, supplied by the
# frontend adapter. Window traversal is generic and independent of any solver.
function core_satisfied(::Val{:slide}, a)
    lists = a.lists
    offsets, collects = a.offsets, a.collects
    length(lists) == length(offsets) == length(collects) || throw(DimensionMismatch("slide lists"))
    all(>(0), offsets) && all(>(0), collects) || throw(ArgumentError("positive slide offsets/collects required"))
    circular = get(a, :circular, false)
    # As in XCSP3's reference parser, the first list controls termination;
    # other lists wrap, including when offsets or lengths differ.
    isempty(lists) && throw(ArgumentError("slide requires at least one list"))
    any(isempty, lists) && return true
    windows = circular ? cld(length(lists[1]), offsets[1]) :
        max(0, fld(length(lists[1]) - collects[1], offsets[1]) + 1)
    for step in 0:(windows - 1)
        window = [lists[j][mod1(step * offsets[j] + k, length(lists[j]))]
            for j in eachindex(lists) for k in 1:collects[j]]
        iszero(a.template(window)) || return false
    end
    return true
end

"""Selected existing evaluator plus structural checks; Boolean fallback is explicit."""
struct CoreEvaluator{K, F}
    error::F
end
CoreEvaluator(::Val{K}) where {K} = CoreEvaluator{K, typeof(haskey(USUAL_CONSTRAINTS, K) ? make_error(K) : nothing)}(
    haskey(USUAL_CONSTRAINTS, K) ? make_error(K) : nothing)
function (e::CoreEvaluator{K})(a) where {K}
    # Preserve existing learned/reference evaluators for undecorated numerical forms.
    if K in (:minimum, :maximum) && !haskey(a, :index) && haskey(a, :condition)
        return e.error(a.list; op = core_operator(a.condition[1]), val = a.condition[2])
    elseif K == :all_equal && !haskey(a, :except)
        return e.error(a.list)
    elseif K == :no_overlap && all(>=(0), a.lengths)
        size(a.origins) == size(a.lengths) || throw(DimensionMismatch("noOverlap origins/lengths"))
        dimension = get(a, :dim, a.origins isa AbstractMatrix ? size(a.origins, 1) : 1)
        return e.error(vec(a.origins); pair_vars = vec(a.lengths), dim = dimension,
            bool = get(a, :zero_ignored, true))
    end
    return Float64(!core_satisfied(Val(K), a))
end
