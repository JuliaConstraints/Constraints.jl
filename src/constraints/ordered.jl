function _concept_ordered(x::T...) where {T <: Number}
    return issorted(x)
end

"""
    ordered(x::Int...)
Global constraint ensuring that all the values of `x` are ordered.
"""
const _ordered = Constraint(
    concept = _concept_ordered,
)
