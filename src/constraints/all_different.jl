## SECTION - all_different and derivative

# all_different
function error_all_different(
    x::V; param=nothing, dom_size=0
) where {T<:Number,V<:AbstractVector{T}}
    acc = Dictionary{T,Int}()
    foreach(y -> insert_or_inc(acc, y), x)
    return Float64(sum(acc .- 1))
end

concept_all_different(x) = allunique(x)

const description_all_different = """Global constraint ensuring that all the values of a given configuration are unique"""

@usual all_different

# all_different_except
concept_all_different_except(x; param) = allunique(Iterators.filter(y -> y ∈ param, x))

const description_all_different_except = """Global constraint ensuring that all the values of a given configuration are unique except for those in the `param` collection."""

# @usual all_different_except 1
