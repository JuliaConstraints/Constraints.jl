function xcsp_channel(list)
    for (i, j) in enumerate(list)
        if i ≤ j
            list[j] == i || return false
        end
    end
    return true
end

function xcsp_channel(l1, l2)
    for (i, j) in enumerate(l2)
        if l1[i] ≠ j || l2[j] ≠ i
            return false
        end
    end
    return true
end

xcsp_channel(; list...) = xcsp_channel(list...)

concept_channel(x; dim = 1) = concept_channel(x, Val(dim))

function concept_channel(x, ::Val{2})
    mid = length(x) ÷ 2
    return xcsp_channel(list = (@view(x[1:mid]), @view(x[mid+1:end])))
end

concept_channel(x, ::Val) = xcsp_channel(list = x)

concept_channel(x::AbstractVector{Bool}; id) = count(x) == 1 == x[id]

const description_channel = """Global constraint ensuring that all ...`"""

@usual cardinality
