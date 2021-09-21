# eq
concept_eq(x) = x[1] == x[2]
const description_eq = """Equality between two variables"""
@usual eq 0 2



# all_equal_param
concept_all_equal_param(x; param) = all(y -> y == param, x)
error_all_equal_param(x; param, dom_size = 0) = count(y -> y != param, x)

"""
    all_equal_param
Global constraint ensuring that all the values of `x` are all equal to a given parameter `param`.
"""
const all_equal_param = Constraint(
    concept = concept_all_equal_param,
    error = make_error(:all_equal_param),
    param = 1,
)

# _sum_equal_param
concept_sum_equal_param(x; param) = sum(x) == param
error_sum_equal_param(x; param, dom_size) = abs(sum(x) - param) / dom_size

"""
    sum_equal_param
Global constraint ensuring that the sum of the values of `x` is equal to a given parameter `param`.
"""
const sum_equal_param = Constraint(
    concept = concept_sum_equal_param,
    error = make_error(:sum_equal_param),
    param = 1,
)

# _minus_equal_param
concept_minus_equal_param(x; param) = x[1] == param + x[2]
error_minus_equal_param(x; param, dom_size) = abs(x[1] - x[2] - param) / dom_size

"""
    minus_equal_param
Constraint ensuring that the difference between `x[1]` and `x[2]` is equal to a given parameter `param`.
"""
const minus_equal_param = Constraint(
    args = 2,
    concept = concept_minus_equal_param,
    error = make_error(:minus_equal_param),
    param = 1,
)
