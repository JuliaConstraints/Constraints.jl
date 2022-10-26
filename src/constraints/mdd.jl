#!SECTION - Multi-valued Decision Diagram

xcsp_mdd(; list, diagram) = accept(diagram, list)

concept_mdd(x; diagram) = xcsp_mdd(; list = x, diagram)

const description_mdd = """Constraint ensuring that the word `x` is recognized by the regular language encoded by `param<:AbstractAutomaton`"""

@usual mdd
