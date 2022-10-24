concept_minimum(x; op = ==, param) = op(min(x), param)

const minimum = Constraint(
    concept = concept_minimum,
    error = make_error(:minimum),
)

@usual minimum
