function error_all_different(x::V; param = nothing, dom_size = 0
) where {T <: Number, V <: AbstractVector{T}}
    acc = Dictionary{T, Int}()
    foreach(y -> insert_or_inc(acc, y), x)
    return Float64(sum(acc .- 1))
end

concept_all_different(x) = allunique(x)

"""
    _all_different
Global constraint ensuring that all the values of a given configuration are unique.
"""
const all_different = Constraint(
    concept = concept_all_different,
    error = make_error(:all_different),
    syms = Set([:permutable]),
)
