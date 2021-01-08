_concept_ordered(x) = issorted(x)

"""
    ordered(x)
Global constraint ensuring that all the values of `x` are ordered.
"""
const _ordered = Constraint(
    concept = _concept_ordered,
)
