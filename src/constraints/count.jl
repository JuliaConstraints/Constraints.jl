concept_count(x; val, op, param) = op(count(y -> y ∈ val, x), param)

concept_at_least(x; val, param) = concept_count(x; val, op = ≥, param)

concept_at_most(x; val, param) = concept_count(x; val, op = ≤, param)

concept_exactly(x; val, param) = concept_count(x; val, op = ==, param)
