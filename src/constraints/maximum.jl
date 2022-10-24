concept_maximum(x; op = ==, param) = op(max(x), param)

const maximum = Constraint(
    concept = concept_maximum,
    error = make_error(:maximum),
)

@usual maximum
