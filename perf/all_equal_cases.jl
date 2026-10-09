module AllEqualCases
import Constraints as C

# Complete former recursive default, including both zero-vector constructions
# when no scalar comparison value is supplied.
original_value(x, val) = all(y -> y == val, x)
original_value(x, ::Nothing) = original(x; val=first(x))
function original(x; val=nothing, pair_vars=zeros(eltype(x), length(x)), op=+)
    if iszero(pair_vars)
        return original_value(x, val)
    end
    aux = map(t -> op(t...), Iterators.zip(x, pair_vars))
    return original_value(aux, val)
end

current_implicit(state) = C.concept_all_equal(state.input)
original_implicit(state) = original(state.input)
current_fixed(state) = C.concept_all_equal(state.input;val=1)
original_fixed(state) = original(state.input;val=1)

function defaults(parameters)
    n = Int(get(parameters, "n", 1000))
    input = ones(Int,n)
    fixed = get(parameters,"comparison","implicit") == "fixed"
    former = get(parameters,"method","current") == "original"
    operation = fixed ? (former ? original_fixed : current_fixed) :
                        (former ? original_implicit : current_implicit)
    return (;prepare=() -> (;input=copy(input)),operation,
        verify=(state,result) -> result === true && state.input == input)
end
end
