function xcsp_no_overlap(origins, lengths, zero_ignored)
    # @info origins lengths collect(zip(origins, lengths))
    previous = (-Inf, -1)
    for t in sort(collect(zip(origins, lengths)))
        zero_ignored && iszero(t[2]) && continue
        sum(previous) ≤ t[1] || return false
        previous = t
    end
    return true
end

function xcsp_no_overlap(
    origins::AbstractVector{NTuple{K,T}},
    lengths::AbstractVector{NTuple{K,T}},
    zero_ignored,
) where {K,T<:Number}
    return all(
        dim -> xcsp_no_overlap(;
            origins=map(t -> t[dim], origins),
            lengths=map(t -> t[dim], lengths),
            zero_ignored),
        1:K,
    )
end

function xcsp_no_overlap(; origins, lengths, zero_ignored=true)
    return xcsp_no_overlap(origins, lengths, zero_ignored)
end

function concept_no_overlap(x, pair_vars, _, bool, ::Val{1})
    return xcsp_no_overlap(; origins=x, lengths=pair_vars, zero_ignored=bool)
end

function concept_no_overlap(x, pair_vars, dim, bool, _)
    l = Int(length(x) ÷ dim)
    # @info l x dim
    origins = reinterpret(reshape, NTuple{dim,eltype(x)}, reshape(x, (dim, l)))
    lengths = reinterpret(reshape, NTuple{dim,eltype(x)}, reshape(pair_vars, (dim, l)))
    return xcsp_no_overlap(; origins, lengths, zero_ignored=bool)
end

const description_no_overlap = """Global constraint ensuring that all ...`"""

@usual function concept_no_overlap(
    x;
    pair_vars=ones(eltype(x), length(x)),
    dim=1,
    bool=true
)
    idim = Int(dim)
    return concept_no_overlap(x, pair_vars, idim, bool, Val(idim))
end

const description_no_overlap_no_zero = """Global constraint ensuring that all ...`"""

@usual function concept_no_overlap_no_zero(x; pair_vars=ones(eltype(x), length(x)), dim=1)
    return concept_no_overlap(x; pair_vars, dim, bool=true)
end

const description_no_overlap_with_zero = """Global constraint ensuring that all ...`"""

@usual function concept_no_overlap_with_zero(x; pair_vars=ones(eltype(x), length(x)), dim=1)
    return concept_no_overlap(x; pair_vars, dim, bool=false)
end
