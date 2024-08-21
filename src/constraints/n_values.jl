#!SECTION - nValues

const description_nvalues = """
Ensures that the number of distinct values in `x` satisfies a given numerical condition. 
The constraint is defined by the following expression: `nValues(x, op, val)` where `x` is a list of variables, `op` is a comparison operator, and `val` is an integer value.
"""

"""
    xcsp_nvalues(list, condition, except)

Return `true` if the number of distinct values in `list` satisfies the given condition, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `condition`: condition to satisfy.
- `except::Union{Nothing, Vector{Int}}`: list of values to exclude. Default is `nothing`.

## Variants
- `:nvalues`: $description_nvalues
```julia
concept(:nvalues, x; op, val)
concept(:nvalues)(x; op, val)
```

## Examples
```julia
c = concept(:nvalues)

c([1, 2, 3, 4, 5]; op = ==, val = 5)
c([1, 2, 3, 4, 5]; op = ==, val = 2)
c([1, 2, 3, 4, 3]; op = <=, val = 5)
c([1, 2, 3, 4, 3]; op = <=, val = 3)
```
"""
function xcsp_nvalues(list, condition, ::Nothing)
    vals = Set{eltype(list)}()
    foreach(v -> push!(vals, v), list)
    return condition[1](length(vals), condition[2])
end

function xcsp_nvalues(list, condition, except)
    return xcsp_nvalues(Iterators.filter(y -> y ∉ except, list), condition, nothing)
end

xcsp_nvalues(; list, condition, except = nothing) = xcsp_nvalues(list, condition, except)

@usual function concept_nvalues(x; op = ==, val, vals = nothing)
    return xcsp_nvalues(list = x, condition = (op, val), except = vals)
end

@testitem "nValues" tags=[:usual, :constraints, :nvalues] begin
    c = USUAL_CONSTRAINTS[:nvalues] |> concept
    e = USUAL_CONSTRAINTS[:nvalues] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 5)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 2)
    @test c([1, 2, 3, 4, 3]; op = <=, val = 5)
    @test !c([1, 2, 3, 4, 3]; op = <=, val = 3)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 2)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 3)
end
