const description_ordered = """
Global constraint ensuring that all the values of `x` are in an increasing order.
"""

const description_increasing = """
Global constraint ensuring that all the values of `x` are in an increasing order.
"""

const description_decreasing = """
Global constraint ensuring that all the values of `x` are in a decreasing order.
"""

const description_strictly_increasing = """
Global constraint ensuring that all the values of `x` are in a strictly increasing order.
"""

const description_strictly_decreasing = """
Global constraint ensuring that all the values of `x` are in a strictly decreasing order.
"""

"""
    xcsp_ordered(list::Vector{Int}, operator, lengths)

Return `true` if all the values of `list` are in an increasing order, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `operator`: comparison operator to use.
- `lengths`: list of lengths to use. Defaults to `nothing`.

## Variants
- `:ordered`: $description_ordered
```julia
concept(:ordered, x; op=≤, pair_vars=nothing)
concept(:ordered)(x; op=≤, pair_vars=nothing)
```
- `:increasing`: $description_increasing
```julia
concept(:increasing, x; op=≤, pair_vars=nothing)
concept(:increasing)(x; op=≤, pair_vars=nothing)
```
- `:decreasing`: $description_decreasing
```julia
concept(:decreasing, x; op=≥, pair_vars=nothing)
concept(:decreasing)(x; op=≥, pair_vars=nothing)
```
- `:strictly_increasing`: $description_strictly_increasing
```julia
concept(:strictly_increasing, x; op=<, pair_vars=nothing)
concept(:strictly_increasing)(x; op=<, pair_vars=nothing)
```
- `:strictly_decreasing`: $description_strictly_decreasing
```julia
concept(:strictly_decreasing, x; op=>, pair_vars=nothing)
concept(:strictly_decreasing)(x; op=>, pair_vars=nothing)
```

## Examples
```julia
c = concept(:ordered)

c([1, 2, 3, 4, 4]; op=≤)
c([1, 2, 3, 4, 5]; op=<)
!c([1, 2, 3, 4, 3]; op=≤)
!c([1, 2, 3, 4, 3]; op=<)
```
"""
function xcsp_ordered(list, operator, ::Nothing)
    for (id, e) in enumerate(list[2:end])
        operator(list[id], e) || (return false)
    end
    return true
end

function xcsp_ordered(list, operator, lengths)
    for (id, e) in enumerate(list[2:end])
        operator(list[id] + lengths[id], e) || (return false)
    end
    return true
end
xcsp_ordered(; list, operator, lengths = nothing) = xcsp_ordered(list, operator, lengths)

@usual function concept_ordered(x; op = ≤, pair_vars = nothing)
    return xcsp_ordered(list = x, operator = op, lengths = pair_vars)
end
@usual concept_increasing(x) = issorted(x)
@usual concept_decreasing(x) = issorted(x; rev = true)
@usual concept_strictly_increasing(x) = concept_ordered(x; op = <)
@usual concept_strictly_decreasing(x) = concept_ordered(x; op = >)

@testitem "Ordered" tags=[:usual, :constraints, :ordered] begin
    c = USUAL_CONSTRAINTS[:ordered] |> concept
    e = USUAL_CONSTRAINTS[:ordered] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 4]; op = ≤)
    @test c([1, 2, 3, 4, 5]; op = <)
    @test !c([1, 2, 3, 4, 3]; op = ≤)
    @test !c([1, 2, 3, 4, 3]; op = <)

    @test vs(c, e, [1, 2, 3, 4, 4]; op = ≤)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = <)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = ≤)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <)
end
