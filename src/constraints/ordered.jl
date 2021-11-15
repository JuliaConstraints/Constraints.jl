concept_ordered(x) = issorted(x)

"""
    ordered(x)
Global constraint ensuring that all the values of `x` are ordered.
"""
const ordered = Constraint(
    concept = concept_ordered,
    error = make_error(:ordered),
)

const description_ordered = """Global constraint ensuring that all the values of `x` are ordered."""

@usual ordered
