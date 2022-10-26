function xcsp_no_overlap(;
    origins,
    lengths,
    zero_ignored = true,
)
    previous = (-Inf, -1)
    for t in sort(zip(origins, lengths))
        zero_ignored && iszero(t[2]) && continue
        sum(previous) ≤ t[1] || return false
        previous = t
    end
    return true
end

function xcsp_no_overlap(;
    origins::AbstractVector{NTuple{K, T}},
    lengths::AbstractVector{NTuple{K, T}},
    zero_ignored = true,
) where {K, T <: Number}
    return all(
        dim -> xcsp_no_overlap(;
            origins = map(t -> t[dim], origins),
            lengths = map(t -> t[dim], lengths),
            zero_ignored),
        1:K,
    )
end

function concept_no_overlap(x, pair_vars, _, zero_ignored, ::Val{1})
    return xcsp_no_overlap(; origins = x, lengths = pair_vars, zero_ignored)
end

function concept_no_overlap(x, pair_vars, dim, zero_ignored, _)
    l = length(x) ÷ dim
    origins = reinterpret(reshape, NTuple{dim, eltype(x)}, reshape(x, (dim, l)))
    lengths = reinterpret(reshape, NTuple{dim, eltype(x)}, reshape(pair_vars, (dim, l)))
    return xcsp_no_overlap(; origins, lengths, zero_ignored)
end

function concept_no_overlap(x; pair_vars=ones(eltype(x), length(x)), dim=1, zero_ignored)
    return concept_no_overlap(x, pair_vars, dim, zero_ignored, Val(dim))
end
