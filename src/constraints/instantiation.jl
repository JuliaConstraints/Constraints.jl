const description_instantiation = """
The instantiation constraint is a global constraint used in constraint programming that ensures that a list of variables takes on a specific set of values in a specific order.
"""

"""
    xcsp_instantiation(; list, values)

Return `true` if the instantiation constraint is satisfied, `false` otherwise. The instantiation constraint is a global constraint used in constraint programming that ensures that a list of variables takes on a specific set of values in a specific order.

## Arguments
- `list::AbstractVector`: list of values to check.
- `values::AbstractVector`: list of values to check against.

## Variants
- `:instantiation`: $description_instantiation
```julia
concept(:instantiation, x; pair_vars)
concept(:instantiation)(x; pair_vars)
```

## Examples
```julia
c = concept(:instantiation)

c([1, 2, 3, 4, 5]; pair_vars=[1, 2, 3, 4, 5])
c([1, 2, 3, 4, 5]; pair_vars=[1, 2, 3, 4, 6])
```
"""
xcsp_instantiation(; list, values) = list == values


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