# _sequential_tasks_param
concept_sequential_tasks(x) = x[1] ≤ x[2] || x[3] ≤ x[4]

"""
    sum_equal_param
Constraint ensuring that the start and completion times of two tasks are not intersecting: `x[1] ≤ x[2] || x[3] ≤ x[4]`.
"""
const sequential_tasks = Constraint(
    args_length = 4,
    concept = concept_sequential_tasks,
    error = make_error(:sequential_tasks),
)
