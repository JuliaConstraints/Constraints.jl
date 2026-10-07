const description_element = """
Global constraint specifying that a variable in `x` indexed by `id` should be equal to a `value`.
"""

"""
    xcsp_element(; list, index, condition)

Return `true` if the element constraint is satisfied, `false` otherwise. The element constraint is a global constraint specifying that a variable in `x` indexed by `id` should be equal to a `value`.

## Arguments
- `list::Union{AbstractVector, Tuple}`: list of values to check.
- `index::Int`: index of the value to check.
- `condition::Tuple`: condition to check.

## Variants
- `:element`: $description_element
```julia
concept(:element, x; id=nothing, op===, val=nothing)
concept(:element)(x; id=nothing, op===, val=nothing)
```

## Examples
```julia
c = concept(:element)

c([1, 2, 3, 4, 5]; id=1, val=1)
c([1, 2, 3, 4, 5]; id=1, val=2)
c([1, 2, 3, 4, 2])
c([1, 2, 3, 4, 1])
```
"""
function xcsp_element(list, index, condition::Tuple)
    return 0 < index ≤ length(list) ? condition[1].(list[index], condition[2]) : false
end
xcsp_element(list, index, value) = xcsp_element(list, index, (==, value))

xcsp_element(; params...) = xcsp_element(params[:list], params[:index], params[:condition])

function concept_element(x, id, op, val)
    return xcsp_element(; list = x, index = id, condition = (op, val))
end

function concept_element(x, ::Nothing, op, ::Nothing)
    return concept_element(x[2:(end - 1)]; id = x[1], op, val = x[end])
end

function concept_element(x, ::Nothing, op, val)
    return concept_element(x[2:end]; id = x[1], op, val)
end

function concept_element(x, id, op, ::Nothing)
    return concept_element(x[1:(end - 1)]; id, op, val = x[end])
end

@usual concept_element(x; id = nothing, op = ==, val = nothing) = concept_element(
    x, id, op, val)

@testitem "Element" tags=[:usual, :constraints, :element] begin
    c = USUAL_CONSTRAINTS[:element] |> concept
    e = USUAL_CONSTRAINTS[:element] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; id = 1, val = 1)
    @test !c([1, 2, 3, 4, 5]; id = 1, val = 2)
    @test c([1, 2, 3, 4, 2])
    @test !c([1, 2, 3, 4, 1])

    @test vs(c, e, [1, 2, 3, 4, 5]; id = 1, val = 1)
    @test vs(c, e, [1, 2, 3, 4, 5]; id = 1, val = 2)
    @test vs(c, e, [1, 2, 3, 4, 2])
    @test vs(c, e, [1, 2, 3, 4, 1])
end
