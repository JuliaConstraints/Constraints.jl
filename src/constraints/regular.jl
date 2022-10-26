xcsp_regular(; list, automaton) = accept(automaton, list)

concept_regular(x; automaton) = xcsp_regular(; list = x, automaton)

const description_regular = """Constraint ensuring that the word `x` is recognized by the regular language encoded by `param<:AbstractAutomaton`"""

@usual regular
