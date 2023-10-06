xcsp_minimum(; list, condition) = condition[1](minimum(list), condition[2])

const description_minimum = """Global constraint ensuring that all ...`"""

@usual concept_minimum(x; op = ==, val) = xcsp_minimum(; list = x, condition = (op, val))

@testitem "Minimum" tags = [:usual, :constraints, :minimum] begin
    c = USUAL_CONSTRAINTS[:minimum] |> concept
    e = USUAL_CONSTRAINTS[:minimum] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 1)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 0)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 1)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 0)
end