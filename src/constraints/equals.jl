# _eq
_concept_eq(x) = x[1] == x[2]

"""
    _eq
Equality between two variables.
"""
const _eq = Constraint(
    args_length = 2,
    concept = _concept_eq,
)

# _all_equal
_concept_all_equal(x) = all(y -> y == x[1], x)

function _error_all_equal(x::V) where {T <: Number, V <: AbstractVector{T}}
    acc = Dictionary{T,Int}()
    foreach(y -> _insert_or_inc(acc, y), x)
    return Float64(length(x) - maximum(acc))
end

"""
    all_equal
Global constraint ensuring that all the values of `x` are all equal.
"""
const _all_equal = Constraint(
    concept = _concept_all_equal,
    error = _error_all_equal,
)

# _all_equal_param
_concept_all_equal_param(x; param) = all(y -> y == param, x)
_error_all_equal_param(x; param) = count(y -> y != param, x)

"""
    all_equal_param
Global constraint ensuring that all the values of `x` are all equal to a given parameter `param`.
"""
const _all_equal_param = Constraint(
    concept = _concept_all_equal_param,
    error = _error_all_equal_param,
    param = 1,
)
