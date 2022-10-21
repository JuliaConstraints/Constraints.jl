#!SECTION - nValues

function concept_nvalues(x; op = ==, param)
    vals = Set{eltype(x)}()
    foreach(v -> push!(vals, v), x)
    return op(length(vals), param)
end

function concept_nvalues(x; except, kwargs...)
    return concept_nvalues(Iterators.filter(y -> y ∉ except, x); kwargs...)
end

const description_nvalues = """Global constraint ensuring that ..."""

@usual nvalues
