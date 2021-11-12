# all_equal
concept_all_equal(x) = all(y -> y == x[1], x)

function error_all_equal(x::V; param = nothing, dom_size = 0
) where {T <: Number, V <: AbstractVector{T}}
    acc = Dictionary{T,Int}()
    foreach(y -> insert_or_inc(acc, y), x)
    return Float64(length(x) - maximum(acc))
end

const description_all_equal = """Global constraint ensuring that all the values of `x` are all equal"""

@usual all_equal
