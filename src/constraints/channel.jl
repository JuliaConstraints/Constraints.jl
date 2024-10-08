const description_channel = """
Ensures that if the i-th element of `x` is assigned the value j, then the j-th element of `x` must be assigned the value i.
"""

"""
    xcsp_channel(; list)

Return `true` if the channel constraint is satisfied, `false` otherwise. The channel constraint ensures that if the i-th element of `list` is assigned the value j, then the j-th element of `list` must be assigned the value i.

## Arguments
- `list::Union{AbstractVector, Tuple}`: list of values to check.

## Variants
- `:channel`: $description_channel
```julia
concept(:channel, x; dim=1, id=nothing)
concept(:channel)(x; dim=1, id=nothing)
```

## Examples
```julia
c = concept(:channel)

c([2, 1, 4, 3])
c([1, 2, 3, 4])
c([2, 3, 1, 4])
c([2, 1, 5, 3, 4, 2, 1, 4, 5, 3]; dim=2)
c([2, 1, 4, 3, 5, 2, 1, 4, 5, 3]; dim=2)
c([false, false, true, false]; id=3)
c([false, false, true, false]; id=1)
```
"""
function xcsp_channel(list::AbstractVector)
    for (i, j) in enumerate(list)
        if i ≤ j
            list[j] == i || return false
        end
    end
    return true
end

function xcsp_channel(list::Tuple)
    l1, l2 = list
    l = length(l1)
    for j in l2
        # @info "debug in" l1 l2 k j list
        0 < j ≤ l || (return false)
        i = l2[j]
        0 < i ≤ l || (return false)
        if l1[i] ≠ j || l2[j] ≠ i
            return false
        end
    end
    return true
end

function xcsp_channel(; list)
    xcsp_channel(values(list))
end
function concept_channel(x, ::Val{2})
    mid = length(x) ÷ 2
    return xcsp_channel(list = (@view(x[1:mid]), @view(x[(mid + 1):end])))
end

concept_channel(x, ::Val) = xcsp_channel(list = x)

concept_channel(x, id) = count(!iszero, x) == 1 == x[id]

@usual function concept_channel(x; dim = 1, id = nothing)
    return isnothing(id) ? concept_channel(x, Val(dim)) : concept_channel(x, id)
end
@testitem "Channel" tags=[:usual, :constraints, :channel] begin
    c = USUAL_CONSTRAINTS[:channel] |> concept
    e = USUAL_CONSTRAINTS[:channel] |> error_f
    vs = Constraints.concept_vs_error

    @test c([2, 1, 4, 3])
    @test c([1, 2, 3, 4])
    @test !c([2, 3, 1, 4])
    @test c([2, 1, 5, 3, 4, 2, 1, 4, 5, 3]; dim = 2)
    @test !c([2, 1, 4, 3, 5, 2, 1, 4, 5, 3]; dim = 2)
    @test c([false, false, true, false]; id = 3)
    @test !c([false, false, true, false]; id = 1)

    @test vs(c, e, [2, 1, 4, 3])
    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [2, 3, 1, 4])
    @test vs(c, e, [2, 1, 5, 3, 4, 2, 1, 4, 5, 3]; dim = 2)
    @test vs(c, e, [2, 1, 4, 3, 5, 2, 1, 4, 5, 3]; dim = 2)
    @test vs(c, e, [false, false, true, false]; id = 3)
    @test vs(c, e, [false, false, true, false]; id = 1)
end
