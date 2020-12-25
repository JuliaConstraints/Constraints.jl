# _eq
_concept_eq(x1, x2) = x1 == x2

"""
    _eq
Equality between two variables.
"""
const _eq = Constraint(
    args_length = 2,
    concept = _concept_eq,
)

# _all_equal
_concept_all_equal(x...) = all(y -> y == x[1], x)

function _error_all_equal(x::T...) where {T <: Number}
    acc = Dictionary{T,Int}()
    foreach(y -> _insert_or_inc(acc, y), x)
    return Float64(length(x) - maximum(acc))
end

const _all_equal = Constraint(
    concept = _concept_all_equal,
    error = _error_all_equal,
)

# _all_equal_param
_concept_all_equal_param(x...; param) = all(y -> y == param, x)
_error_all_equal_param(x...; param) = count(y -> y != param, x)

const _all_equal_param = Constraint(
    concept = _concept_all_equal_param,
    error = _error_all_equal_param,
    param = 1,
)

"""
    all_equal(x::Int...; param::T)
    all_equal(x::Int...)
Global constraint ensuring that all the values of `x` are all_equal (to param if given).
"""