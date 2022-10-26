function xcsp_cumulative(; origins, lengths, heights, condition)
    acc = Dict{eltype(origins), Int}()
    for t in sort(zip(origins, lengths, heights))
        foreach(t -> t ≤ t[1] && delete!(acc, t), keys(acc))
        incsert!(acc, t[1] + t[2], t[3])
        condition[1](sum(values(acc)), condition[2]) || return false
    end
    return true
end

function concept_cumulative(x, pair_vars, op, val)
    return xcsp_cumulative(
        origins = x, lengths = pair_vars[1], heights = pair_vars[2], condition = (op, val)
    )
end

function concept_cumulative(x, pair_vars::Vector{T}, op, val) where {T <: Number}
    return concept_cumulative(x, fill(pair_vars, 2), op, val)
end

function concept_cumulative(x; pair_vars = ones(eltype(x), length(x)), op = ≤, val)
    return concept_cumulative(x, pair_vars, op, val)
end
