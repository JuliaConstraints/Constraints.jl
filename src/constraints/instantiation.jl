xcsp_instantiation(; list, values) = list == values

const description_instantiation = """Global constraint ensuring that all ...`"""

@usual concept_instantiation(x; pair_vars) = xcsp_instantiation(list=x, values=pair_vars)

@testitem "Instantiation" tags = [:usual, :constraints, :instantiation] begin
    c = USUAL_CONSTRAINTS[:instantiation] |> concept
    e = USUAL_CONSTRAINTS[:instantiation] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; pair_vars=[1, 2, 3, 4, 5])
    @test !c([1, 2, 3, 4, 5]; pair_vars=[1, 2, 3, 4, 6])

    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars=[1, 2, 3, 4, 5])
    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars=[1, 2, 3, 4, 6])
end