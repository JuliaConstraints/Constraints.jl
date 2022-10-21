function concept_sum(x; param, kwargs...)
    coefs = get(kwargs, :coefs, ones(eltype(x), length(x)))
    op = get(kwargs, :op, ==)
    return op(sum(coefs .* x), param)
end

"""
    sum(x; param)
Global constraint ensuring that ...
"""
const sum = Constraint(
    concept = concept_sum,
    error = make_error(:sum),
)

const description_sum = """Global constraint ensuring that ..."""

@usual sum
