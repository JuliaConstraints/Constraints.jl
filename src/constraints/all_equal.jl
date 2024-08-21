#!SECTION - all_equal

const description_all_equal = """
Global constraint ensuring that the values in `x` are all equal.
"""

concept_all_equal(x, val) = all(y -> y == val, x)

"""
    xcsp_all_equal(list::Vector{Int}, val::Int)

Return `true` if all the values of `list` are equal to `val`, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `val::Int`: value to compare to.

## Variants
- `:all_equal`: $description_all_equal
```julia
concept(:all_equal, x; val=nothing, pair_vars=zeros(x), op=+)
concept(:all_equal)(x; val=nothing, pair_vars=zeros(x), op=+)
```

## Examples
```julia
c = concept(:all_equal)

c([0, 0, 0, 0])
c([1, 2, 3, 4])
c([3, 2, 1, 0]; pair_vars=[0, 1, 2, 3])
c([0, 1, 2, 3]; pair_vars=[0, 1, 2, 3])
c([1, 2, 3, 4]; op=/, val=1, pair_vars=[1, 2, 3, 4])
c([1, 2, 3, 4]; op=*, val=1, pair_vars=[1, 2, 3, 4])
```
"""
xcsp_all_equal(; list) = concept_all_equal(list; val = first(list))

@usual function concept_all_equal(x; val = nothing, pair_vars = zero(x), op = +)
    if iszero(pair_vars)
        return concept_all_equal(x, val)
    else
        aux = map(t -> op(t...), Iterators.zip(x, pair_vars))
        return concept_all_equal(aux, val)
    end
end
concept_all_equal(x, ::Nothing) = xcsp_all_equal(list = x)

## SECTION - Test Items
@testitem "All Equal" tags=[:usual, :constraints, :all_equal] begin
    c = USUAL_CONSTRAINTS[:all_equal] |> concept
    e = USUAL_CONSTRAINTS[:all_equal] |> error_f
    vs = Constraints.concept_vs_error

    @test c([0, 0, 0, 0])
    @test !c([1, 2, 3, 4])
    @test c([3, 2, 1, 0]; pair_vars = [0, 1, 2, 3])
    @test !c([0, 1, 2, 3]; pair_vars = [0, 1, 2, 3])
    @test c([1, 2, 3, 4]; op = /, val = 1, pair_vars = [1, 2, 3, 4])
    @test !c([1, 2, 3, 4]; op = *, val = 1, pair_vars = [1, 2, 3, 4])

    @test vs(c, e, [0, 0, 0, 0])
    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [3, 2, 1, 0]; pair_vars = [0, 1, 2, 3])
    @test vs(c, e, [0, 1, 2, 3]; pair_vars = [0, 1, 2, 3])
    @test vs(c, e, [1, 2, 3, 4]; op = /, val = 1, pair_vars = [1, 2, 3, 4])
    @test vs(c, e, [1, 2, 3, 4]; op = *, val = 1, pair_vars = [1, 2, 3, 4])
end
