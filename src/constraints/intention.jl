## NOTE - constraints of type intension represent general predicate over a set of variables

# Dist different TODO - check if a better name exists
concept_dist_different(x) = abs(x[1] - x[2]) ≠ abs(x[3] - x[4])

const description_dist_different = """Local constraint ensuring that `concept(dist_different, x) = |x[1] - x[2]| ≠ |x[3] - x[4]|)`"""

# 0 parameters, 4 variables
@usual dist_different 0 4
