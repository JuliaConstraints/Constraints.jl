function concept_ordered(x; op = ≤)
    for (id, e) in enumerate(x[2:end])
        op(x[id], e) || (return false)
    end
    return true
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

@usual ordered

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

@usual increasing

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

@usual decreasing

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

@usual strictly_increasing

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

@usual strictly_decreasing
