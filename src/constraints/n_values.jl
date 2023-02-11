#!SECTION - nValues

function xcsp_nvalues(list, condition, ::Nothing)
    vals = Set{eltype(list)}()
    foreach(v -> push!(vals, v), list)
    return condition[1](length(vals), condition[2])
end

function xcsp_nvalues(list, condition, except)
    return xcsp_nvalues(Iterators.filter(y -> y ∉ except, list), condition, nothing)
end

xcsp_nvalues(; list, condition, except = nothing) = xcsp_nvalues(list, condition, except)

const description_nvalues = """Global constraint ensuring that ..."""

@usual function concept_nvalues(x; op = ==, val, vals = nothing)
    return xcsp_nvalues(list = x, condition = (op, val), except = vals)
end
