#!SECTION - Multi-valued Decision Diagram

const description_mdd = """
    Multi-valued Decision Diagram (MDD) constraint.

    The MDD constraint is a constraint that can be used to model a wide range of problems. It is a directed graph where each node is labeled with a value and each edge is labeled with a value. The constraint is satisfied if there is a path from the first node to the last node such that the sequence of edge labels is a valid sequence of the value labels.
"""

"""
    xcsp_mdd(; list, diagram)

Return a function that checks if the list of values `list` satisfies the MDD `diagram`.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `diagram::MDD`: MDD to check.

## Variants
- `:mdd`: $description_mdd
```julia
concept(:mdd, x; language)
concept(:mdd)(x; language)
```

## Examples
```julia
c = concept(:mdd)

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

c([0,2,0]; language = a)
c([1,2,0]; language = a)
c([2,0,0]; language = a)
c([2,1,2]; language = a)
c([1,0,2]; language = a)
c([0,1,2]; language = a)
```
"""
xcsp_mdd(; list, diagram) = accept(diagram, list)

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
