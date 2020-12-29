function _error_all_different(x::T...) where {T <: Number}
    acc = Dictionary{T, Int}()
    foreach(y -> _insert_or_inc(acc, y), x)
    return Float64(sum(acc .- 1))
end

function _concept_all_different(x::T...) where {T <: Number}
    return allunique(x)
end

"""
    _all_different
Global constraint ensuring that all the values of a given configuration are unique.
"""
const _all_different = Constraint(
    concept = _concept_all_different,
    error = _error_all_different,
)
