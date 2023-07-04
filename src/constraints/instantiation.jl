xcsp_instantiation(; list, values) = list == values

const description_instantiation = """Global constraint ensuring that all ...`"""

@usual concept_instantiation(x; pair_vars) = xcsp_instantiation(list=x, values=pair_vars)
