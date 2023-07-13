xcsp_sum(; list, coeffs, condition) = condition[1](sum(coeffs .* list), condition[2])

const description_sum = """Global constraint ensuring that `op(sum(x *. pair_vars), val)` is true. Defaults to `op = ==` and `pair_vars = ones(eltype(x), length(x))`"""

@usual function concept_sum(x; op = ==, pair_vars = ones(eltype(x), length(x)), val)
    return xcsp_sum(list = x, coeffs = pair_vars, condition = (op, val))
end

@testitem "sum" tags = [:usual, :constraints, :sum] begin
    c = USUAL_CONSTRAINTS[:sum] |> concept
    e = USUAL_CONSTRAINTS[:sum] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 15)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 2)
    @test c([1, 2, 3, 4, 3]; op = <=, val = 15)
    @test !c([1, 2, 3, 4, 3]; op = <=, val = 3)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 15)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 2)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 15)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 3)
end