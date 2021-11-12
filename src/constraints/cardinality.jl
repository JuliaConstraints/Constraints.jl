# cardinality (or global_cardinality or gcc)
function concept_cardinality(x; param)
    d = Dict{eltype(param).types[1],Int}()
    for y in x
        y ∈ Iterators.map(x -> first(x), param) && (d[y] = get!(d, y, 0) + 1)
    end
    for (k, r) in param
        d[k] ∈ r || return false
    end
    return true
end

const description_cardinality = """Global constraint ensuring that all the values of a given configuration have the cardinality of the values in `param`, a collection of `Pair{T, UnitRange{Int}}`"""

@usual cardinality

# TODO - cardinality_closed
