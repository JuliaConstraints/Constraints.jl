xcsp_instantiation(; list, values) = list == values

concept_instantiation(x; vals) = xcsp_instantiation(list = x, values = vals)

const description_instantiation = """Global constraint ensuring that all ...`"""

@usual instantiation
