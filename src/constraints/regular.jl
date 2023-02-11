xcsp_regular(; list, automaton) = accept(automaton, list)

const description_regular = """Constraint ensuring that the word `x` is recognized by the regular language encoded by `param<:AbstractAutomaton`"""

@usual concept_regular(x; language) = xcsp_regular(; list = x, automaton = language)
