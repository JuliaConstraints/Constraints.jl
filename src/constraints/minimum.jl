const description_minimum = """
The minimum constraint is a global constraint used in constraint programming that specifies that a certain condition should hold for the minimum value in a list of variables.
"""

"""
    xcsp_minimum(; list, condition)

Return `true` if the minimum constraint is satisfied, `false` otherwise. The minimum constraint is a global constraint used in constraint programming that specifies that a certain condition should hold for the minimum value in a list of variables.

## Arguments
- `list::Union{AbstractVector, Tuple}`: list of values to check.
- `condition::Tuple`: condition to check.

## Variants
- `:minimum`: $description_minimum
```julia
concept(:minimum, x; op, val)
concept(:minimum)(x; op, val)
```

## Examples
```julia
c = concept(:minimum)

c([1, 2, 3, 4, 5]; op = ==, val = 1)
c([1, 2, 3, 4, 5]; op = ==, val = 0)
```
"""
xcsp_minimum(; list, condition) = condition[1](minimum(list), condition[2])

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