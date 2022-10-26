function xcsp_ordered(list, op, ::Nothing)
    for (id, e) in enumerate(list[2:end])
        operator(list[id], e) || (return false)
    end
    return true
end

function xcsp_ordered(list, operator, lengths)
    for (id, e) in enumerate(list[2:end])
        operator(list[id] + lengths[id], e) || (return false)
    end
    return true
end
xcsp_ordered(; list, operator, lengths = nothing) = xcsp_ordered(list, operator, lengths)

function concept_ordered(x; op = ≤, pair_vars = nothing)
    return xcsp_ordered(list = x, operator = op, lengths = pair_vars)
end

"""
    ordered(x; param = ≤)
Global constraint ensuring that all the values of `x` are ordered by `param`.
"""
const ordered = Constraint(
    concept = concept_ordered,
    error = make_error(:ordered),
)

const description_ordered = """Global constraint ensuring that all the values of `x` are ordered."""

concept_increasing(x) = issorted(x)

"""
    increasing(x)
Global constraint ensuring that all the values of `x` are in an increasing order.
"""
const increasing = Constraint(
    concept = concept_increasing,
    error = make_error(:increasing),
)

const description_increasing = """Global constraint ensuring that all the values of `x` are in an increasing order."""

concept_decreasing(x) = issorted(x; rev=true)

"""
    decreasing(x)
Global constraint ensuring that all the values of `x` are in a decreasing order.
"""
const decreasing = Constraint(
    concept = concept_decreasing,
    error = make_error(:decreasing),
)

const description_decreasing = """Global constraint ensuring that all the values of `x` are in a decreasing order."""

concept_strictly_increasing(x) = concept_ordered(x; op = <)

"""
    strictly_increasing(x)
Global constraint ensuring that all the values of `x` are in a strictly increasing order.
"""
const strictly_increasing = Constraint(
    concept = concept_strictly_increasing,
    error = make_error(:strictly_increasing),
)

const description_sctrictly_increasing = """Global constraint ensuring that all the values of `x` are in a strictly increasing order."""

concept_strictly_decreasing(x) = concept_ordered(x; op = >)

"""
    strictly_decreasing(x)
Global constraint ensuring that all the values of `x` are in a strictly decreasing order.
"""
const sctrictly_decreasing = Constraint(
    concept = concept_strictly_decreasing,
    error = make_error(:strictly_decreasing),
)

const description_strictly_decreasing = """Global constraint ensuring that all the values of `x` are in a strictly decreasing order."""

@usual ordered decreasing strictly_decreasing increasing strictly_increasing
