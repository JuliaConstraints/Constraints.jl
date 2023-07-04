#!SECTION - all_different

xcsp_all_different(list, ::Nothing) = allunique(list)

function xcsp_all_different(list, except)
    return xcsp_all_different(list=Iterators.filter(x -> x ∉ except[:, 1], list))
end

xcsp_all_different(; list, except=nothing) = xcsp_all_different(list, except)

const description_all_different = """Global constraint ensuring that all the values of a given configuration are unique"""

@usual concept_all_different(x; vals=nothing) = xcsp_all_different(list=x, except=vals)

## SECTION - Test Items
@testitem "All Different" tags = [:usual, :constraints, :all_different] begin
    c = USUAL_CONSTRAINTS[:all_different] |> concept
    e = USUAL_CONSTRAINTS[:all_different] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4])
    @test !c([1, 2, 3, 1])
    @test c([1, 0, 0, 4]; vals=[0])
    @test !c([1, 0, 0, 1]; vals=[0])

    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [1, 2, 3, 1])
    @test vs(c, e, [1, 0, 0, 4]; vals=[0])
    @test vs(c, e, [1, 0, 0, 1]; vals=[0])
end
