function xcsp_circuit(; list, size = nothing)
    return if isnothing(size)
        concept_circuit(list)
    else
        concept_circuit(list, op = ==, val = size)
    end
end

const description_circuit = "Global constraint ensuring that the values of `x` form a circuit. If the indices of the variables are not `1:length(x)`, the indices can be indicated as the `param` collection"

# circuit (full circuit)
@usual function concept_circuit(x; op = ≥, val = 1)
    s = Set(1:length(x))
    cycle = 0
    current = Vector{eltype(x)}()
    while !isempty(s)
        @info "entering while loop" s current cycle op val
        u = 0
        if isempty(current)
            u = pop!(s)
        elseif x[last(current)] ∈ current
            cycle = max(cycle, length(current) - getindex(current, u))
            op(cycle, val) ? (return true) : break
        else
            pop!(s, x[last(current)], 0)
        end
        u = isempty(current) ? pop!(s) : pop!(s, x[last(current)], 0)
        if iszero(u)
            empty!(current)
            @info "iszero(u)" s current cycle op val
            continue
        end

        if u ∈ current
            @info "$u ∈ $current"
            cycle = max(cycle, length(current) - getindex(current, u))
            op(cycle, val) ? (return true) : break
        end

        @warn "pushing $u to $current"
        push!(current, u)
    end
    u = last(current)
    if x[u] ∈ current
        cycle = max(cycle, length(current) - getindex(current, u))
    end
    return op(cycle, val)
end

## SECTION - Test Items
@testitem "Circuit" tags = [:usual, :constraints, :circuit] begin
    c = USUAL_CONSTRAINTS[:circuit] |> concept
    e = USUAL_CONSTRAINTS[:circuit] |> error_f
    vs = Constraints.concept_vs_error

    # @test c([2, 3, 1, 4])
    @test c([4, 3, 1, 3])
end
