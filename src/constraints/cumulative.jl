function concept_cumulative(
    x;
    lengths = ones(eltype(x), length(x)),
    heigths = ones(eltype(x), length(x)),
    op = ≤,
    param,
)
    function incsert!(d::Dictionary, ind, val = 1)
        return set!(d, ind, isassigned(d, ind) ? d[ind] + val : val)
    end

    acc = Dict{eltype(x), Int}()
    for t in sort(zip(x, lengths, heigths))
        foreach(t -> t ≤ t[1] && delete!(acc, t), keys(acc))
        incsert!(acc, t[1] + t[2], t[3])
        op(sum(values(acc)), param) || return false
    end
    return true
end
