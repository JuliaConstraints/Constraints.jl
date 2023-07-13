xcsp_maximum(; list, condition) = condition[1](maximum(list), condition[2])

const description_maximum = """Global constraint ensuring that all ...`"""

@usual concept_maximum(x; op = ==, val) = xcsp_maximum(; list = x, condition = (op, val))

@testitem "Maximum" tags = [:usual, :constraints, :maximum] begin
    c = USUAL_CONSTRAINTS[:maximum] |> concept
    e = USUAL_CONSTRAINTS[:maximum] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 5)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 6)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 6)
end