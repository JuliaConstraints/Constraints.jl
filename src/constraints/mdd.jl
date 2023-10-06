#!SECTION - Multi-valued Decision Diagram

xcsp_mdd(; list, diagram) = accept(diagram, list)

const description_mdd = """Constraint ensuring that the word `x` is recognized by the regular language encoded by `param<:AbstractAutomaton`"""

@usual concept_mdd(x; language) = xcsp_mdd(; list = x, diagram = language)

@testitem "MDD" tags = [:usual, :constraints, :mdd] default_imports = false begin
    using ConstraintCommons
    using Constraints
    using Test

    c = USUAL_CONSTRAINTS[:mdd] |> concept
    e = USUAL_CONSTRAINTS[:mdd] |> error_f
    vs = Constraints.concept_vs_error

    states = [
        Dict( # level x1
            (:r, 0) => :n1,
            (:r, 1) => :n2,
            (:r, 2) => :n3,
        ),
        Dict( # level x2
            (:n1, 2) => :n4,
            (:n2, 2) => :n4,
            (:n3, 0) => :n5,
        ),
        Dict( # level x3
            (:n4, 0) => :t,
            (:n5, 0) => :t,
        ),
    ]
    a = MDD(states)

    @test c([0,2,0]; language = a)
    @test c([1,2,0]; language = a)
    @test c([2,0,0]; language = a)
    @test !c([2,1,2]; language = a)
    @test !c([1,0,2]; language = a)
    @test !c([0,1,2]; language = a)

    @test vs(c, e, [0,2,0]; language = a)
    @test vs(c, e, [1,2,0]; language = a)
    @test vs(c, e, [2,0,0]; language = a)
    @test vs(c, e, [2,1,2]; language = a)
    @test vs(c, e, [1,0,2]; language = a)
    @test vs(c, e, [0,1,2]; language = a)
end
