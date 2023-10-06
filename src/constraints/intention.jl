#!NOTE - constraints of type intension represent general predicate over a set of variables

# TODO - Add a DSL for intension (cf XCSP3-core)

const description_dist_different = """Local constraint ensuring that `concept(dist_different, x) = |x[1] - x[2]| ≠ |x[3] - x[4]|`"""

"""
    xcsp_intension(list, predicate)

An intensional constraint is usually defined from a `predicate` over `x`. As such it encompass any generic constraint.
"""
xcsp_intension(; list, predicate) = predicate(list)

# Dist different TODO - check if a better name exists
predicate_dist_different(x) = abs(x[1] - x[2]) ≠ abs(x[3] - x[4])

@usual concept_dist_different(x) = xcsp_intension(list = x, predicate = predicate_dist_different)

@testitem "Dist different (intension)" tags = [:usual, :constraints, :intension] begin
    c = USUAL_CONSTRAINTS[:dist_different] |> concept
    e = USUAL_CONSTRAINTS[:dist_different] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 3])
    @test !c([1, 2, 3, 4])

    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [1, 2, 3, 3])
end