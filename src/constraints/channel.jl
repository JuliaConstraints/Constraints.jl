function concept_channel(x)
    for (i, j) in enumerate(x)
        if i ≤ j
            x[j] == i || return false
        end
    end
    return true
end

function concept_channel(x, y)
    for (i, j) in enumerate(y)
        if x[i] ≠ j || y[j] ≠ i
            return false
        end
    end
    return true
end