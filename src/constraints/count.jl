function xcsp_count(; list, values, condition)
    return condition[1](count(y -> y ∈ values, list), condition[2])
end

const description_count = """Constraint ensuring that ...`"""

@usual concept_count(x; vals, op, val) = xcsp_count(list = x, values = vals, condition = (op, val))

const description_at_least = """Constraint ensuring that ...`"""

@usual concept_at_least(x; vals, val) = concept_count(x; vals, op = ≥, val)

const description_at_most = """Constraint ensuring that ...`"""

@usual concept_at_most(x; vals, val) = concept_count(x; vals, op = ≤, val)

const description_exactly = """Constraint ensuring that ...`"""

@usual concept_exactly(x; vals, val) = concept_count(x; vals, op = ==, val)

## SECTION - Test Items
@testitem "Count" tags = [:usual, :constraints, :count] begin
    c = USUAL_CONSTRAINTS[:count] |> concept
    e = USUAL_CONSTRAINTS[:count] |> error_f
    vs = Constraints.concept_vs_error

    c_at_least = USUAL_CONSTRAINTS[:at_least] |> concept
    e_at_least = USUAL_CONSTRAINTS[:at_least] |> error_f

    c_at_most = USUAL_CONSTRAINTS[:at_most] |> concept
    e_at_most = USUAL_CONSTRAINTS[:at_most] |> error_f

    c_exactly = USUAL_CONSTRAINTS[:exactly] |> concept
    e_exactly = USUAL_CONSTRAINTS[:exactly] |> error_f

    @test c([2, 1, 4, 3]; vals = [1, 2, 3, 4], op = ≥, val = 2) && c_at_least([2, 1, 4, 3]; vals = [1, 2, 3, 4], val = 2)
    @test c([1, 2, 3, 4]; vals = [1, 2], op = ==, val = 2) && c_exactly([1, 2, 3, 4]; vals = [1, 2], val = 2)
    @test !c([2, 1, 4, 3]; vals = [1, 2], op = ≤, val = 1) && !c_at_most([2, 1, 4, 3]; vals = [1, 2], val = 1)

    @test vs(c, e, [2, 1, 4, 3]; vals = [1, 2, 3, 4], op = ≥, val = 2)
    @test vs(c_at_least, e_at_least, [2, 1, 4, 3]; vals = [1, 2, 3, 4], val = 2)
    @test vs(c, e, [1, 2, 3, 4]; vals = [1, 2], op = ==, val = 2)
    @test vs(c_exactly, e_exactly, [1, 2, 3, 4]; vals = [1, 2], val = 2)
    @test vs(c, e, [2, 1, 4, 3]; vals = [1, 2], op = ≤, val = 2)
    @test vs(c_at_most, e_at_most, [2, 1, 4, 3]; vals = [1, 2], val = 1)
end