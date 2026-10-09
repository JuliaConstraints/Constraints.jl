module SumCases
import Constraints as C

original(x; op = ==, pair_vars = ones(eltype(x), length(x)), val) =
    op(sum(pair_vars .* x), val)
current(state) = C.concept_sum(state.input; val = state.target)
former(state) = original(state.input; val = state.target)

function defaults(parameters)
    n = Int(get(parameters, "n", 1000))
    input = ones(Int, n)
    target = sum(input)
    operation = get(parameters, "method", "current") == "original" ? former : current
    return (; prepare = () -> (; input = copy(input), target), operation,
        verify = (state, result) -> result === true && state.input == input)
end
end
