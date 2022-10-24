# cardinality (or global_cardinality or gcc)
function concept_cardinality(x; closed=false, vals, occurs)
    counts = zeros(Int, Indices(vals))
    for t in x
        if t ∉ vals
            closed && (return false)
            continue
        else
            incsert!(counts, t)
        end
    end
    for v in vals
        counts[v] ∈ occurs(v) || (return false)
    end
    return true
end

const description_cardinality = """Global constraint ensuring that all ...`"""

@usual cardinality
