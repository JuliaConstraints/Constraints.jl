function concept_no_overlap(x; lengths = ones(eltype(x), length(x)), zero_ignored = true)
    previous = (-Inf, -1)
    for t in sort(zip(x, lengths))
        zero_ignored && iszero(t[2]) && continue
        sum(previous) ≤ t[1] || return false
        previous = t
    end
    return true
end

function concept_no_overlap(
    x::AbstractVector{NTuple{K, T}};
    lengths::AbstractVector{NTuple{K, T}},
    zero_ignored = true,
) where {K, T <: Number}
    return all(
        dim -> concept_no_overlap(
            map(t -> t[dim], x);
            lengths = map(t -> t[dim], lengths),
            zero_ignored),
        1:dim,
    )
end
