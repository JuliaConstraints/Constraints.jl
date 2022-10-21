# Multi-valued Decision Diagram
struct MDD{S,T}
    states::Vector{Dict{Tuple{S,T},S}}
end

function accept(a::MDD, w)

    for c in w
        s = get(a.states, (s, c), nothing)
        isnothing(s) && return false
    end
    return s == a.finish
end