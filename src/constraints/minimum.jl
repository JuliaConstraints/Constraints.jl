xcsp_minimum(; list, condition) = condition[1](minimum(list), condition[2])

const description_minimum = """Global constraint ensuring that all ...`"""

@usual concept_minimum(x; op = ==, val) = xcsp_minimum(; list = x, condition = (op, val))
