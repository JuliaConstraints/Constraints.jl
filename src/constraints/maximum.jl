xcsp_maximum(; list, condition) = condition[1](max(list), condition[2])

concept_maximum(x; op = ==, val) = xcsp_maximum(; list = x, condition = (op, val))

const maximum = Constraint(
    concept = concept_maximum,
    error = make_error(:maximum),
)

@usual maximum
