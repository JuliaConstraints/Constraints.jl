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
    Base.require_one_based_indexing(list)
    n = length(list)
    for (i, j) in enumerate(list)
        j isa Integer || return false
        1 ≤ j ≤ n || return false
        @inbounds list[j] == i || return false
    end
    return true
end

function xcsp_channel(list::Tuple)
    l1, l2 = list
    Base.require_one_based_indexing(l1, l2)
    length(l1) == length(l2) || return false
    n = length(l1)
    @inbounds for i in eachindex(l1)
        j = l1[i]
        j isa Integer || return false
        1 ≤ j ≤ n || return false
        l2[j] == i || return false
    end
    @inbounds for j in eachindex(l2)
        i = l2[j]
        i isa Integer || return false
        1 ≤ i ≤ n || return false
        l1[i] == j || return false
    end
    return true
end

function xcsp_channel(; list)
    xcsp_channel(values(list))
end
function concept_channel(x::AbstractVector, ::Val{2})
    iseven(length(x)) || return false
    mid = length(x) ÷ 2
    return xcsp_channel(list = (@view(x[1:mid]), @view(x[(mid + 1):end])))
end

concept_channel(x, ::Val{2}) = concept_channel(collect(x), Val(2))

concept_channel(x, ::Val{1}) = xcsp_channel(list = x)
concept_channel(x, ::Val) = false

function concept_channel(x, id::Integer)
    Base.require_one_based_indexing(x)
    1 ≤ id ≤ length(x) || return false
    return count(!iszero, x) == 1 && isone(@inbounds x[id])
end

concept_channel(x, id) = false

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
    @test !c([0, 1, 1])
    @test !c([2, 0])
    @test !c([1, 2, 3]; dim = 2)
    @test !c([1, 2]; dim = 3)
    @test !c([false, true]; id = 0)
    @test !c([false, true]; id = 3)

    @test vs(c, e, [2, 1, 4, 3])
    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [2, 3, 1, 4])
    @test vs(c, e, [2, 1, 5, 3, 4, 2, 1, 4, 5, 3]; dim = 2)
    @test vs(c, e, [2, 1, 4, 3, 5, 2, 1, 4, 5, 3]; dim = 2)
    @test vs(c, e, [false, false, true, false]; id = 3)
    @test vs(c, e, [false, false, true, false]; id = 1)
end
