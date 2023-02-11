xcsp_maximum(; list, condition) = condition[1](maximum(list), condition[2])

const description_maximum = """Global constraint ensuring that all ...`"""

@usual concept_maximum(x; op = ==, val) = xcsp_maximum(; list = x, condition = (op, val))
