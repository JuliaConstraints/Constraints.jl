# cardinality (or global_cardinality or gcc)

function xcsp_cardinality(; list, values, occurs, closed = false)
    counts = zeros(Int, Indices(values))
    for t in list
        if t ∉ values
            closed && (return false)
            continue
        else
            incsert!(counts, t)
        end
    end
    for v in values
        counts[v] ∈ occurs[v] || (return false)
    end
    return true
end

function concept_cardinality(x; closed = false, vals)
    values = vals[1]
    occurs = vals[2]
    return xcsp_cardinality(; list = x, values, occurs, closed)
end

const description_cardinality = """Global constraint ensuring that all ...`"""

@usual cardinality
