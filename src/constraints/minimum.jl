concept_minimum(x; param) = minimum(x) < param

const _minimum = Constraint(
    concept = concept_minimum,
    error = make_error(:minimum),
)

@usual minimum
