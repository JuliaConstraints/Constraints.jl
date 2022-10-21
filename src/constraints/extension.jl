## NOTE - constraints of type extension represent a list of supported or conflicted tuples

concept_support(x; param) = x ∈ param

const description_support = """Global constraint ensuring that `x` is in the set of configurations given by `param`: `x ∈ param`"""

@usual support 1

concept_conflict(x; param) = x ∉ param

const description_conflict = """Global constraint ensuring that `x` is not in the set of configurations given by `param`: `x ∉ param`"""

@usual conflict 1