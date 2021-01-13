function _error_all_different(x::V) where {T <: Number, V <: AbstractVector{T}}
    acc = Dictionary{T, Int}()
    foreach(y -> _insert_or_inc(acc, y), x)
    return Float64(sum(acc .- 1))
end

_concept_all_different(x) = allunique(x)

"""
    _all_different
Global constraint ensuring that all the values of a given configuration are unique.
"""
const _all_different = Constraint(
    concept = _concept_all_different,
    error = _make_error(:all_different),
    syms = Set([:permutable]),
)
