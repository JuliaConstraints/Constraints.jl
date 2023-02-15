#!SECTION - all_equal

const description_all_equal = """Global constraint ensuring that all the values of `x` are all equal"""

concept_all_equal(x, val) = all(y -> y == val, x)

xcsp_all_equal(; list) = concept_all_equal(list; val=first(list))

@usual function concept_all_equal(x; val=nothing, pair_vars=zero(x))
    return concept_all_equal(x+pair_vars, val)
end
concept_all_equal(x, ::Nothing) = xcsp_all_equal(list=x)
