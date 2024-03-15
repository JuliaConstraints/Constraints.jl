const description_count = """
Constraint ensuring that the number of occurrences of the values in `vals` in `x` satisfies the given condition.
"""

const description_at_least = """
Constraint ensuring that the number of occurrences of the values in `vals` in `x` is at least `val`.
"""

const description_at_most = """
Constraint ensuring that the number of occurrences of the values in `vals` in `x` is at most `val`.
"""

const description_exactly = """
Constraint ensuring that the number of occurrences of the values in `vals` in `x` is exactly `val`.
"""

"""
    xcsp_count(list, values, condition)

Return `true` if the number of occurrences of the values in `values` in `list` satisfies the given condition, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `values::Vector{Int}`: list of values to check.
- `condition`: condition to satisfy.

## Variants
- `:count`: $description_count
```julia
concept(:count, x; vals, op, val)
concept(:count)(x; vals, op, val)
```
- `:at_least`: $description_at_least
```julia
concept(:at_least, x; vals, val)
concept(:at_least)(x; vals, val)
```
- `:at_most`: $description_at_most
```julia
concept(:at_most, x; vals, val)
concept(:at_most)(x; vals, val)
```
- `:exactly`: $description_exactly
```julia
concept(:exactly, x; vals, val)
concept(:exactly)(x; vals, val)
```

## Examples
```julia
c = concept(:count)

c([2, 1, 4, 3]; vals=[1, 2, 3, 4], op=≥, val=2)
c([1, 2, 3, 4]; vals=[1, 2], op==, val=2)
c([2, 1, 4, 3]; vals=[1, 2], op=≤, val=1)
```
"""
function xcsp_count(; list, values, condition)
    return condition[1](count(y -> y ∈ values, list), condition[2])
end

@usual concept_count(x; vals, op, val) = xcsp_count(list = x, values = vals, condition = (op, val))
@usual concept_at_least(x; vals, val) = concept_count(x; vals, op = ≥, val)
@usual concept_at_most(x; vals, val) = concept_count(x; vals, op = ≤, val)
@usual concept_exactly(x; vals, val) = concept_count(x; vals, op = ==, val)

## SECTION - Test Items
@testitem "Count" tags = [:usual, :constraints, :count] begin
    c = USUAL_CONSTRAINTS[:count] |> concept
    e = USUAL_CONSTRAINTS[:count] |> error_f
    vs = Constraints.concept_vs_error

    c_at_least = USUAL_CONSTRAINTS[:at_least] |> concept
    e_at_least = USUAL_CONSTRAINTS[:at_least] |> error_f

    c_at_most = USUAL_CONSTRAINTS[:at_most] |> concept
    e_at_most = USUAL_CONSTRAINTS[:at_most] |> error_f

    c_exactly = USUAL_CONSTRAINTS[:exactly] |> concept
    e_exactly = USUAL_CONSTRAINTS[:exactly] |> error_f

    @test c([2, 1, 4, 3]; vals = [1, 2, 3, 4], op = ≥, val = 2) && c_at_least([2, 1, 4, 3]; vals = [1, 2, 3, 4], val = 2)
    @test c([1, 2, 3, 4]; vals = [1, 2], op = ==, val = 2) && c_exactly([1, 2, 3, 4]; vals = [1, 2], val = 2)
    @test !c([2, 1, 4, 3]; vals = [1, 2], op = ≤, val = 1) && !c_at_most([2, 1, 4, 3]; vals = [1, 2], val = 1)

    @test vs(c, e, [2, 1, 4, 3]; vals = [1, 2, 3, 4], op = ≥, val = 2)
    @test vs(c_at_least, e_at_least, [2, 1, 4, 3]; vals = [1, 2, 3, 4], val = 2)
    @test vs(c, e, [1, 2, 3, 4]; vals = [1, 2], op = ==, val = 2)
    @test vs(c_exactly, e_exactly, [1, 2, 3, 4]; vals = [1, 2], val = 2)
    @test vs(c, e, [2, 1, 4, 3]; vals = [1, 2], op = ≤, val = 2)
    @test vs(c_at_most, e_at_most, [2, 1, 4, 3]; vals = [1, 2], val = 1)
end