xcsp_regular(; list, automaton) = accept(automaton, list)

const description_regular = """Constraint ensuring that the word `x` is recognized by the regular language encoded by `param<:AbstractAutomaton`"""

@usual concept_regular(x; language) = xcsp_regular(; list = x, automaton = language)

@testitem "regular" tags = [:usual, :constraints, :regular] default_imports = false begin
    using ConstraintCommons
    using Constraints
    using Test

    c = USUAL_CONSTRAINTS[:regular] |> concept
    e = USUAL_CONSTRAINTS[:regular] |> error_f
    vs = Constraints.concept_vs_error

    states = Dict(
        (:a, 0) => :a,
        (:a, 1) => :b,
        (:b, 1) => :c,
        (:c, 0) => :d,
        (:d, 0) => :d,
        (:d, 1) => :e,
        (:e, 0) => :e,
    )
    start = :a
    finish = :e
    a = Automaton(states, start, finish)

    @test c([0,0,1,1,0,0,1,0,0]; language = a)
    @test !c([1,1,1,0,1]; language = a)

    @test vs(c, e, [0,0,1,1,0,0,1,0,0]; language = a)
    @test vs(c, e, [1,1,1,0,1]; language = a)
end