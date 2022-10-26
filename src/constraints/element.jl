xcsp_element(; list, index, condition) = condition[1].(list[index], condition[2])

xcsp_element(; list, index, value) = xcsp_element(; list, index, condition = (==, value))

function concept_element(x; id, op = ==, val)
    return xcsp_element(list = x, index = id, condition = (op, val))
end

concept_element(x; op = ==) = concept_element(x[2:end-1]; id=x[1], op, val=x[end])
