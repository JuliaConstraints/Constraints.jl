# _sequential_tasks_param
concept_sequential_tasks(x) = x[1] ≤ x[2] || x[3] ≤ x[4]

"""
    sum_equal_param
Global constraint ensuring that the sum of the values of `x` is equal to a given parameter `param`.
"""
const sequential_tasks = Constraint(
    args_length = 4,
    concept = concept_sequential_tasks,
    error = make_error(:sequential_tasks),
)
