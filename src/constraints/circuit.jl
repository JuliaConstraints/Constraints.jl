# circuit (full circuit)
function concept_circuit(x; op = ≥, size = 1)
    s = Set(1:length(x))
    d = Dict{Int, Int}()
    while !isempty(s)
        u = pop!(s)
        push!(d, u => 0)
        l = 0
        while !isempty(s)
            v = pop!(s, x[u], 0)
            if iszero(v)
                break
            end
            l += 1
            δ = get!(d, v, l) - l
            !iszero(δ) && op(δ, size) && (return true)
            u = v
        end
        setdiff!(s, keys(d))
    end
    return false
end

const description_circuit = "Global constraint ensuring that the values of `x` form a circuit. If the indices of the variables are not `1:length(x)`, the indices can be indicated as the `param` collection"
