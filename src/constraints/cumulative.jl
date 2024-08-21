const description_cumulative = """
Global constraint ensuring that for any point in time, the sum of the "heights" of tasks that are ongoing at that time does not exceed a certain limit. Often used in scheduling problems
"""

"""
    xcsp_cumulative(; origins, lengths, heights, condition)

Return `true` if the cumulative constraint is satisfied, `false` otherwise. The cumulative constraint is a global constraint ensuring that for any point in time, the sum of the "heights" of tasks that are ongoing at that time does not exceed a certain limit.

## Arguments
- `origins::AbstractVector`: list of origins of the tasks.
- `lengths::AbstractVector`: list of lengths of the tasks.
- `heights::AbstractVector`: list of heights of the tasks.
- `condition::Tuple`: condition to check.

## Variants
- `:cumulative`: $description_cumulative
```julia
concept(:cumulative, x; pair_vars, op, val)
concept(:cumulative)(x; pair_vars, op, val)
```

## Examples
```julia
c = concept(:cumulative)

c([1, 2, 3, 4, 5]; val = 1)
c([1, 2, 2, 4, 5]; val = 1)
c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = ≤, val = 5)
c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = <, val = 5)
```
"""
function xcsp_cumulative(; origins, lengths, heights, condition)
    tasks = Vector{Tuple{eltype(origins), eltype(origins)}}()
    for t in Iterators.zip(origins, lengths, heights)
        push!(tasks, (t[1], t[3]))
        push!(tasks, (t[1] + t[2], -t[3]))
    end
    η = zero(eltype(origins))
    for t in sort!(tasks)
        η += t[2]
        condition[1](η, condition[2]) || return false
    end
    return true
end

function concept_cumulative(x, pair_vars, op, val)
    return xcsp_cumulative(
        origins = x,
        lengths = pair_vars[1, :],
        heights = pair_vars[2, :],
        condition = (op, val)
    )
end

function concept_cumulative(x, pair_vars::Vector{T}, op, val) where {T <: Number}
    return concept_cumulative(x, fill(pair_vars, 2), op, val)
end

@usual function concept_cumulative(
        x;
        pair_vars = ones(eltype(x), (2, length(x))),
        op = ≤,
        val
)
    return concept_cumulative(x, pair_vars, op, val)
end

@testitem "Cumulative" tags=[:usual, :constraints, :cumulative] begin
    c = USUAL_CONSTRAINTS[:cumulative] |> concept
    e = USUAL_CONSTRAINTS[:cumulative] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; val = 1)
    @test !c([1, 2, 2, 4, 5]; val = 1)
    @test c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = ≤, val = 5)
    @test !c([1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = <, val = 5)

    @test vs(c, e, [1, 2, 3, 4, 5]; val = 1)
    @test vs(c, e, [1, 2, 2, 4, 5]; val = 1)
    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = ≤, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars = [3 2 5 4 2; 1 2 1 1 3], op = <, val = 5)
end
