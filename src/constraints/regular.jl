const description_regular = """
    Ensures that a sequence `x` (interpreted as a word) is accepted by the regular language represented by a given automaton. This constraint verifies the compliance of `x` with the language rules encoded within the `automaton` parameter, which must be an instance of `<:AbstractAutomaton`.
"""

"""
    xcsp_regular(; list, automaton)

$description_regular

## Arguments
- `list::Vector{Int}`: A list of variables
- `automaton<:AbstractAutomaton`: An automaton representing the regular language

## Variants
- `:regular`: $description_regular
```julia
concept(:regular, x; language)
concept(:regular)(x; language)
```

## Examples
```julia
c = concept(:regular)

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

c([0,0,1,1,0,0,1,0,0]; language = a)
c([1,1,1,0,1]; language = a)
```
"""
xcsp_regular(; list, automaton) = accept(automaton, list)

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
