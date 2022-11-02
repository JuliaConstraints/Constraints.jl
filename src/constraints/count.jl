function xcsp_count(; list, values, condition)
    return condition[1](count(y -> y ∈ values, list), condition[2])
end

concept_count(x; vals, op, val) = xcsp_count(list = x, values = vals, condition = (op, val))

const description_count = """Constraint ensuring that ...`"""

@usual count

concept_at_least(x; vals, val) = concept_count(x; vals, op = ≥, val)

const description_at_least = """Constraint ensuring that ...`"""

@usual at_least

concept_at_most(x; vals, val) = concept_count(x; vals, op = ≤, val)

const description_at_most = """Constraint ensuring that ...`"""

@usual at_most

concept_exactly(x; vals, val) = concept_count(x; vals, op = ==, val)

const description_exactly = """Constraint ensuring that ...`"""

@usual exactly
