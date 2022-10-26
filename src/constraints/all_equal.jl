#!SECTION - all_equal

concept_all_equal(x; val::T) where {T <: Number} = all(y -> y == val, x)

xcsp_all_equal(; list) = concept_all_equal(list; val = first(list))

concept_all_equal(x) = xcsp_all_equal(list = x)

const description_all_equal = """Global constraint ensuring that all the values of `x` are all equal"""
