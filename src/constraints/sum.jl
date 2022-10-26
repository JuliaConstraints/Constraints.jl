xcsp_sum(; list, coeffs, condition) = condition[1](sum(coeffs .* list), condition[2])

function concept_sum(x; op = ==, pair_vars = ones(eltype(x), length(x)), val)
    return xcsp_sum(list = x, coeffs = pair_vars, condition = (op, val))
end

const description_sum = """Global constraint ensuring that ..."""

@usual sum
