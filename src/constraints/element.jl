function xcsp_element(list, index, condition::Tuple)
    condition[1].(list[index], condition[2])
end
xcsp_element(list, index, value) = xcsp_element(list, index, (==, value))

xcsp_element(; params...) = xcsp_element(params[:list], params[:index], params[:condition])

function concept_element(x, id, op, val)
    return xcsp_element(; list = x, index = id, condition = (op, val))
end

function concept_element(x, ::Nothing, op, ::Nothing)
    return concept_element(x[2:end-1]; id=x[1], op, val=x[end])
end

const description_element = """Global constraint ensuring that all ...`"""

@usual concept_element(x; id = nothing, op = ==, val = nothing) = concept_element(x, id, op, val)

@testitem "Element" tags = [:usual, :constraints, :element] begin
    c = USUAL_CONSTRAINTS[:element] |> concept
    e = USUAL_CONSTRAINTS[:element] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; id=1, val=1)
    @test !c([1, 2, 3, 4, 5]; id=1, val=2)
    @test c([1, 2, 3, 4, 2])
    @test !c([1, 2, 3, 4, 1])

    @test vs(c, e, [1, 2, 3, 4, 5]; id=1, val=1)
    @test vs(c, e, [1, 2, 3, 4, 5]; id=1, val=2)
    @test vs(c, e, [1, 2, 3, 4, 2])
    @test vs(c, e, [1, 2, 3, 4, 1])
end