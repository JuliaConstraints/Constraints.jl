#!SECTION - Multi-valued Decision Diagram

xcsp_mdd(; list, diagram) = accept(diagram, list)

const description_mdd = """Constraint ensuring that the word `x` is recognized by the regular language encoded by `param<:AbstractAutomaton`"""

@usual concept_mdd(x; language) = xcsp_mdd(; list = x, diagram = language)
