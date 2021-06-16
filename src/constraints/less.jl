# _less_than_param
concept_less_than_param(x; param) = x[1] ≤ param
error_less_than_param(x; param, dom_size = 0) = max(0.0, x[1] - param) / dom_size

"""
    less_than_param
Constraint ensuring that the value of `x` is less than a given parameter `param`.
"""
const less_than_param = Constraint(
    args_length = 1,
    concept = concept_less_than_param,
    error = make_error(:less_than_param),
    param = 1,
)
