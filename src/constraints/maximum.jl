concept_maximum(x; op = ==, param) = op(max(x), param)

const maximum = Constraint(
    concept = concept_minimum,
    error = make_error(:minimum),
)

@usual maximum
