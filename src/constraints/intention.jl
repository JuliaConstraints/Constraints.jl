concept_dist_different(x) = abs(x[1] - x[2]) ≠ abs(x[3] - x[4])

const description_dist_different = """Local constraint ensuring that `concept(dist_different, x) = |x[1] - x[2]| ≠ |x[3] - x[4]|)`"""

@usual dist_different 0 4
