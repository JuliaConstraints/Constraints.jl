concept_element(x; id, op = ==, param) = op(x[id], val)

concept_element(x; op = ==) = concept_element(x[2:end-1]; id=x[1], val=x[end], op)