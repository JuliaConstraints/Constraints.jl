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
concept_element(x; id = nothing, op = ==, val = nothing) = concept_element(x, id, op, val)

const description_element = """Global constraint ensuring that all ...`"""

@usual element
