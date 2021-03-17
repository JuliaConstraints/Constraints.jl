concept_dist_different(x) = abs(x[1] - x[2]) ≠ abs(x[3] - x[4])

"""
    dist_different
Local constraint ensuring that `concept(dist_different, x) = |x[1] - x[2]| ≠ |x[3] - x[4]|)`.
"""
const dist_different = Constraint(
    args_length = 4,
    concept = concept_dist_different,
)
