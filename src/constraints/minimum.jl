xcsp_minimum(; list, condition) = condition[1](min(list), condition[2])

concept_minimum(x; op = ==, val) = xcsp_minimum(; list = x, condition = (op, val))

const minimum = Constraint(
    concept = concept_minimum,
    error = make_error(:minimum),
)

@usual minimum
