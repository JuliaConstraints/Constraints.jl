# cardinality (or global_cardinality or gcc)

const description_cardinality = """Global constraint ensuring that all ...`"""
const description_cardinality_closed = """Global constraint ensuring that all ...`"""
const description_cardinality_open = """Global constraint ensuring that all ...`"""

function xcsp_cardinality(; list, values, occurs, closed=false)
    counts = zeros(Int, Indices(distinct(values)))
    for t in list
        if t ∉ values
            closed && (return false)
            continue
        else
            incsert!(counts, t)
        end
    end
    for (id, v) in enumerate(values)
        counts[v] ∈ occurs[id] || (return false)
    end
    return true
end

@usual function concept_cardinality(x; bool=false, vals)
    values = vals[1]
    occurs = if length(vals) ≥ 3
        map(i -> vals[2][i]:(vals[2][i] ≤ vals[3][i] ? 1 : -1):(vals[3][i]), 1:length(vals[1]))
    else
        vals[2]
    end
    return xcsp_cardinality(; list=x, values, occurs, closed=bool)
end

@usual concept_cardinality_closed(x; vals) = concept_cardinality(x; bool=true, vals)
@usual concept_cardinality_open(x; vals) = concept_cardinality(x; bool=false, vals)
