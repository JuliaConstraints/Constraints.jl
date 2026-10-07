const description_circuit = """
Global constraint ensuring that the values of `x` form a circuit, i.e., a sequence where each value is the index of the next value in the sequence, and the sequence eventually loops back to the start. Often used for routing problems.
"""

"""
    xcsp_circuit(; list, size)

Return `true` if the circuit constraint is satisfied, `false` otherwise. The circuit constraint is a global constraint ensuring that the values of `x` form a circuit, i.e., a sequence where each value is the index of the next value in the sequence, and the sequence eventually loops back to the start.

## Arguments
- `list::AbstractVector`: list of values to check.
- `size::Int`: size of the circuit.

## Variants
- `:circuit`: $description_circuit
```julia
concept(:circuit, x; op, val)
concept(:circuit)(x; op, val)
```

## Examples
```julia
c = concept(:circuit)

c([1, 2, 3, 4])
c([2, 3, 4, 1])
c([2, 3, 1, 4]; op = ==, val = 3)
c([4, 3, 1, 3]; op = >, val = 0)
```
"""
function xcsp_circuit(; list, size = nothing)
    return if isnothing(size)
        concept_circuit(list)
    else
        concept_circuit(list, op = ==, val = size)
    end
end

"""Return the unique non-trivial cycle size, or `nothing` for an invalid subcircuit."""
function _subcircuit_size(x)
    Base.require_one_based_indexing(x)
    n = length(x)
    n >= 2 || return nothing

    first_active = 0
    active_count = 0
    @inbounds for index in eachindex(x)
        successor = x[index]
        successor isa Integer || return nothing
        1 <= successor <= n || return nothing
        if successor != index
            iszero(first_active) && (first_active = index)
            active_count += 1
        end
    end
    active_count >= 2 || return nothing

    visited = falses(n)
    current = first_active
    @inbounds for _ in 1:active_count
        visited[current] && return nothing
        visited[current] = true
        current = Int(x[current])
        x[current] == current && return nothing
    end
    current == first_active || return nothing
    @inbounds for index in eachindex(x)
        visited[index] == (x[index] != index) || return nothing
    end
    return active_count
end

# XCSP3 circuit is a single non-trivial subcircuit; unused nodes self-loop.
@usual function concept_circuit(x; op = ≥, val = 2)
    cycle_size = _subcircuit_size(x)
    return !isnothing(cycle_size) && op(cycle_size, val)
end

## SECTION - Test Items
@testitem "Circuit" tags=[:usual, :constraints, :circuit] begin
    c = USUAL_CONSTRAINTS[:circuit] |> concept
    e = USUAL_CONSTRAINTS[:circuit] |> error_f
    vs = Constraints.concept_vs_error

    @test !c([1, 2, 3, 4])
    @test c([2, 3, 4, 1])
    @test c([2, 3, 1, 4])
    @test c([2, 3, 1, 4]; op = ==, val = 3)
    @test !c([4, 3, 1, 3]; op = >, val = 0)
    @test !c([2, 1, 4, 3])
    @test !c([2, 3, 5, 1])
    @test !c([2, 3, 0, 1])
    @test !c([2, 3, 1]; op = ==, val = 2)

    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [2, 3, 4, 1])
    @test vs(c, e, [2, 3, 1, 4])
    @test vs(c, e, [2, 3, 1, 4]; op = ==, val = 3)
    @test vs(c, e, [4, 3, 1, 3]; op = >, val = 0)
end
