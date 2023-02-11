#!SECTION - all_different

xcsp_all_different(list, ::Nothing) = allunique(list)

function xcsp_all_different(list, except)
    return xcsp_all_different(list=Iterators.filter(x -> x ∉ except, list))
end

xcsp_all_different(; list, except=nothing) = xcsp_all_different(list, except)

const description_all_different = """Global constraint ensuring that all the values of a given configuration are unique"""

@usual concept_all_different(x; vals=nothing) = xcsp_all_different(list=x, except=vals)
