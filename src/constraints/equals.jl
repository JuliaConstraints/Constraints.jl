# eq
concept_eq(x) = x[1] == x[2]

"""
    eq
Equality between two variables.
"""
const eq = Constraint(
    args_length = 2,
    concept = concept_eq,
    error = make_error(:eq),
)

# _all_equal
concept_all_equal(x) = all(y -> y == x[1], x)

function error_all_equal(x::V; param = nothing, dom_size = 0
) where {T <: Number, V <: AbstractVector{T}}
    acc = Dictionary{T,Int}()
    foreach(y -> insert_or_inc(acc, y), x)
    return Float64(length(x) - maximum(acc))
end

"""
    all_equal
Global constraint ensuring that all the values of `x` are all equal.
"""
const all_equal = Constraint(
    concept = concept_all_equal,
    error = make_error(:all_equal),
)

# all_equal_param
concept_all_equal_param(x; param) = all(y -> y == param, x)
error_all_equal_param(x; param, dom_size = 0) = count(y -> y != param, x)

"""
    all_equal_param
Global constraint ensuring that all the values of `x` are all equal to a given parameter `param`.
"""
const all_equal_param = Constraint(
    concept = concept_all_equal_param,
    error = error_all_equal_param,
    param = 1,
)

# _sum_equal_param
_concept_sum_equal_param(x; param) = sum(x) == param
_error_sum_equal_param(x; param, dom_size) = ceil(abs(sum(x) - param) / dom_size)

"""
    sum_equal_param
Global constraint ensuring that the sum of the values of `x` is equal to a given parameter `param`.
"""
const _sum_equal_param = Constraint(
    concept = _concept_sum_equal_param,
    error = _error_sum_equal_param,
    param = 1,
)