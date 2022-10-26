xcsp_maximum(; list, condition) = condition[1](max(list), condition[2])

concept_maximum(x; op = ==, val) = xcsp_maximum(; list = x, condition = (op, val))

const description_maximum = """Global constraint ensuring that all ...`"""

@usual maximum
