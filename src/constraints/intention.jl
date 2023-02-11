#!NOTE - constraints of type intension represent general predicate over a set of variables

const description_dist_different = """Local constraint ensuring that `concept(dist_different, x) = |x[1] - x[2]| ≠ |x[3] - x[4]|`"""

"""
    xcsp_intension(list, predicate)

An intensional constraint is usually defined from a `predicate` over `x`. As such it encompass any generic constraint.
"""
xcsp_intension(; list, predicate) = predicate(list)

# Dist different TODO - check if a better name exists
predicate_dist_different(x) = abs(x[1] - x[2]) ≠ abs(x[3] - x[4])

@usual concept_dist_different(x) = xcsp_intension(list = x, predicate = predicate_dist_different)
