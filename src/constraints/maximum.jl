const description_maximum = """
The maximum constraint is a global constraint used in constraint programming that specifies that a certain condition should hold for the maximum value in a list of variables.
"""

"""
    xcsp_maximum(; list, condition)

Return `true` if the maximum constraint is satisfied, `false` otherwise. The maximum constraint is a global constraint used in constraint programming that specifies that a certain condition should hold for the maximum value in a list of variables.

## Arguments
- `list::Union{AbstractVector, Tuple}`: list of values to check.
- `condition::Tuple`: condition to check.

## Variants
- `:maximum`: $description_maximum
```julia
concept(:maximum, x; op, val)
concept(:maximum)(x; op, val)
```

## Examples
```julia
c = concept(:maximum)

c([1, 2, 3, 4, 5]; op = ==, val = 5)
c([1, 2, 3, 4, 5]; op = ==, val = 6)
```
"""
xcsp_maximum(; list, condition) = condition[1](maximum(list), condition[2])

@usual concept_maximum(x; op = ==, val) = xcsp_maximum(; list = x, condition = (op, val))

@testitem "Maximum" tags=[:usual, :constraints, :maximum] begin
    c = USUAL_CONSTRAINTS[:maximum] |> concept
    e = USUAL_CONSTRAINTS[:maximum] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 5)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 6)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 6)
end
