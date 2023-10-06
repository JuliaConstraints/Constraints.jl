function xcsp_circuit(; list, size = nothing)
    return if isnothing(size)
        concept_circuit(list)
    else
        concept_circuit(list, op = ==, val = size)
    end
end

const description_circuit = "Global constraint ensuring that the values of `x` form a circuit. If the indices of the variables are not `1:length(x)`, the indices can be indicated as the `param` collection"

# circuit (full circuit)
@usual function concept_circuit(x; op = ≥, val = length(x))
    V = Set(1:length(x))
    S = Vector{eltype(x)}()
    D = Set{Int}()

    while !isempty(V)
        v = isempty(S) ? pop!(V) : pop!(V, x[last(S)])
        push!(S, v)
        notvalid = false
        (cycle = x[v] ∈ S) || (notvalid = (v == x[v] || x[v] ∉ V || x[v] ∈ D))
        if cycle
            λ = length(S) - findfirst(u -> u == x[v], S) + 1
            op(λ, val) && return true
        end
        if cycle || notvalid
            union!(D, S)
            empty!(S)
        end
    end
    return false
end

## SECTION - Test Items
@testitem "Circuit" tags = [:usual, :constraints, :circuit] begin
    c = USUAL_CONSTRAINTS[:circuit] |> concept
    e = USUAL_CONSTRAINTS[:circuit] |> error_f
    vs = Constraints.concept_vs_error

    @test !c([1, 2, 3, 4])
    @test c([2, 3, 4, 1])
    @test c([2, 3, 1, 4]; op = ==, val = 3)
    @test c([4, 3, 1, 3]; op = >, val = 0)

    @test vs(c, e, [1, 2, 3, 4])
    @test vs(c, e, [2, 3, 4, 1])
    @test vs(c, e, [2, 3, 1, 4]; op = ==, val = 3)
    @test vs(c, e, [4, 3, 1, 3]; op = >, val = 0)
end
