# circuit (full circuit)
function concept_circuit(x; param=1:length(x))
    i, j = first(param), first(x)
    for acc in 1:(length(x) - 1)
        j == first(param) && return false
        i, j = j, x[j]
    end
    return j == first(param)
end

const description_circuit = "Global constraint ensuring that the values of `x` form a circuit. If the indices of the variables are not `1:length(x)`, the indices can be indicated as the `param` collection"

# @usual circuit 1

# TODO - subcircuit
