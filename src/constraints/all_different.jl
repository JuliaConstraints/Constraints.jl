#!SECTION - all_different

function error_all_different(
    x::V; param=nothing, dom_size=0
) where {T<:Number,V<:AbstractVector{T}}
    acc = Dictionary{T,Int}()
    foreach(y -> insert_or_inc(acc, y), x)
    return Float64(sum(acc .- 1))
end

concept_all_different(x) = allunique(x)

function concept_all_different(x; except)
    return concept_all_different(Iterators.filter(y -> y ∉ except, x))
end

const description_all_different = """Global constraint ensuring that all the values of a given configuration are unique"""

@usual all_different
