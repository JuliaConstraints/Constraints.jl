concept_count(x; val, op, param) = op(count(y -> y ∈ val, x), param)

const description_count = """Constraint ensuring that ...`"""

@usual count

concept_at_least(x; val, param) = concept_count(x; val, op = ≥, param)

const description_at_least = """Constraint ensuring that ...`"""

@usual at_least

concept_at_most(x; val, param) = concept_count(x; val, op = ≤, param)

const description_at_most = """Constraint ensuring that ...`"""

@usual at_most

concept_exactly(x; val, param) = concept_count(x; val, op = ==, param)

const description_exactly = """Constraint ensuring that ...`"""

@usual exactly
