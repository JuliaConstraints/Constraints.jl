#!NOTE - constraints of type intension represent general predicate over a set of variables

# TODO - Add a DSL for intension (cf XCSP3-core)

const description_dist_different = """
A constraint ensuring that the distances between marks on the ruler are unique. Specifically, it checks that the distance between `x[1]` and `x[2]`, and the distance between `x[3]` and `x[4]`, are different. This constraint is fundamental in ensuring the validity of a Golomb ruler, where no two pairs of marks should have the same distance between them.
"""

"""
    xcsp_intension(list, predicate)

An intensional constraint is usually defined from a `predicate` over `list`. As such it encompass any generic constraint.

# Arguments
- `list::Vector{Int}`: A list of variables
- `predicate::Function`: A predicate over `list`

# Variants
- `:dist_different`: $description_dist_different
```julia
concept(:dist_different, x)
concept(:dist_different)(x)
```

# Examples
````julia
using Constraints # hide
c = concept(:dist_different)
c([1, 2, 3, 3]) && !c([1, 2, 3, 4])
````

"""
xcsp_intension(; list, predicate) = predicate(list)

# Dist different TODO - check if a better name exists
predicate_dist_different(x) = abs(x[1] - x[2]) ≠ abs(x[3] - x[4])

@usual concept_dist_different(x) = xcsp_intension(
    list = x, predicate = predicate_dist_different)

@testitem "Dist different (intension)" tags=[:usual, :constraints, :intension] begin
    c = USUAL_CONSTRAINTS[:dist_different] |> concept
    e = USUAL_CONSTRAINTS[:dist_different] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 3])
    @test !c([1, 2, 3, 4])

    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [1, 2, 3, 3])
end
