module OrderedCases
import Constraints as C

function copied_ordered(values, offsets)
    for (i, value) in enumerate(values[2:end])
        values[i] + offsets[i] <= value || return false
    end
    true
end
current(state) = C.xcsp_ordered(state.values, <=, state.offsets)
original(state) = copied_ordered(state.values, state.offsets)

function ordered(parameters)
    n = Int(get(parameters, "n", 1000))
    values = collect(1:n)
    offsets = zeros(Int, n)
    operation = get(parameters, "method", "current") == "original" ? original : current
    (; prepare=() -> (; values=copy(values), offsets=copy(offsets)), operation,
        verify=(state, result) -> result === true && state.values == values && state.offsets == offsets)
end
end
