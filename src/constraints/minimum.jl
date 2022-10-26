xcsp_minimum(; list, condition) = condition[1](min(list), condition[2])

concept_minimum(x; op = ==, val) = xcsp_minimum(; list = x, condition = (op, val))

const description_minimum = """Global constraint ensuring that all ...`"""

@usual minimum
