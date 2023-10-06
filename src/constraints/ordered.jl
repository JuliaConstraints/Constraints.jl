function xcsp_ordered(list, operator, ::Nothing)
    for (id, e) in enumerate(list[2:end])
        operator(list[id], e) || (return false)
    end
    return true
end

function xcsp_ordered(list, operator, lengths)
    for (id, e) in enumerate(list[2:end])
        operator(list[id] + lengths[id], e) || (return false)
    end
    return true
end
xcsp_ordered(; list, operator, lengths = nothing) = xcsp_ordered(list, operator, lengths)

const description_ordered = """Global constraint ensuring that all the values of `x` are ordered."""

@usual function concept_ordered(x; op = ≤, pair_vars = nothing)
    return xcsp_ordered(list = x, operator = op, lengths = pair_vars)
end

const description_increasing = """Global constraint ensuring that all the values of `x` are in an increasing order."""

@usual concept_increasing(x) = issorted(x)

const description_decreasing = """Global constraint ensuring that all the values of `x` are in a decreasing order."""

@usual concept_decreasing(x) = issorted(x; rev=true)

const description_sctrictly_increasing = """Global constraint ensuring that all the values of `x` are in a strictly increasing order."""

@usual concept_strictly_increasing(x) = concept_ordered(x; op = <)

const description_strictly_decreasing = """Global constraint ensuring that all the values of `x` are in a strictly decreasing order."""

@usual concept_strictly_decreasing(x) = concept_ordered(x; op = >)

@testitem "Ordered" tags = [:usual, :constraints, :ordered] begin
    c = USUAL_CONSTRAINTS[:ordered] |> concept
    e = USUAL_CONSTRAINTS[:ordered] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 4]; op = ≤)
    @test c([1, 2, 3, 4, 5]; op = <)
    @test !c([1, 2, 3, 4, 3]; op = ≤)
    @test !c([1, 2, 3, 4, 3]; op = <)

    @test vs(c, e, [1, 2, 3, 4, 4]; op = ≤)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = <)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = ≤)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <)
end