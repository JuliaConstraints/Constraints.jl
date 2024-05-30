const description_sum = """
Global constraint ensuring that the sum of the variables in `x` satisfies a given condition.
"""

"""
    xcsp_sum(list, coeffs, condition)

Return `true` if the sum of the variables in `list` satisfies the given condition, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `coeffs::Vector{Int}`: list of coefficients to use.
- `condition`: condition to satisfy.

## Variants
- `:sum`: $description_sum
```julia
concept(:sum, x; op===, pair_vars=ones(x), val)
concept(:sum)(x; op===, pair_vars=ones(x), val)
```

## Examples
```julia
c = concept(:sum)

c([1, 2, 3, 4, 5]; op===, val=15)
c([1, 2, 3, 4, 5]; op===, val=2)
c([1, 2, 3, 4, 3]; op=≤, val=15)
c([1, 2, 3, 4, 3]; op=≤, val=3)
```
"""
xcsp_sum(; list, coeffs, condition) = condition[1](sum(coeffs .* list), condition[2])

@usual function concept_sum(x; op = ==, pair_vars = ones(eltype(x), length(x)), val)
    return xcsp_sum(list = x, coeffs = pair_vars, condition = (op, val))
end

@testitem "sum" tags=[:usual, :constraints, :sum] begin
    c = USUAL_CONSTRAINTS[:sum] |> concept
    e = USUAL_CONSTRAINTS[:sum] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 15)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 2)
    @test c([1, 2, 3, 4, 3]; op = <=, val = 15)
    @test !c([1, 2, 3, 4, 3]; op = <=, val = 3)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 15)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 2)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 15)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 3)
end
