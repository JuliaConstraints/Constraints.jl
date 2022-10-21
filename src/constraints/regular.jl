#TODO - Look for an automata/regular language support package] -> Automa.jl

abstract type AbstractAutomaton end

# Determnistic Automaton
struct Automaton{S,T} <: AbstractAutomaton
    states::Dict{Tuple{S,T},S}
    start::S
    finish::S
end

function accept(a::Automaton, w)
    s = a.start
    for c in w
        s = get(a.states, (s, c), nothing)
        isnothing(s) && return false
    end
    return s == a.finish
end

concept_regular(x; automaton) = accept(automaton, x)

const description_regular = """Constraint ensuring that the word `x` is recognized by the regular language encoded by `param<:AbstractAutomaton`"""

@usual regular

# d = Dict(
#     (:a, 0) => :a,
#     (:a, 1) => :b,
#     (:b, 1) => :c,
#     (:c, 0) => :d,
#     (:d, 0) => :d,
#     (:d, 1) => :e,
#     (:e, 0) => :e,
# )

# a = Automaton(d, :a, :e)

# accept(a, [1, 1, 0, 1])
