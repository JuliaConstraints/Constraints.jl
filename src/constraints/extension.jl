##!NOTE - constraints of type extension represent a list of supported or conflicted tuples

# TODO - Better input for conflicts and supports (cf XCSP3-core)

xcsp_extension(list, ::Nothing, conflicts) = list ∉ conflicts
xcsp_extension(list, supports, _) = list ∈ supports

function xcsp_extension(; list, supports=nothing, conflicts=nothing)
    return xcsp_extension(list, supports, conflicts)
end

function concept_extension(x, pair_vars::Vector{T}) where {T <: Number}
    return xcsp_extension(list = x, supports = pair_vars)
end

function concept_extension(x, pair_vars)
    supports = pair_vars[1]
    conflicts = pair_vars[2]
    return xcsp_extension(; list = x, supports) || xcsp_extension(; list = x, conflicts)
end

const description_extension = """Global constraint ensuring that `x` is in the set of configurations given by `pair_vars[1]` and not in the set given by `pair_vars[2]`: `x ∈ pair_vars[1] || x ∉ pair_vars[2]`"""

@usual concept_extension(x; pair_vars) = concept_extension(x, pair_vars)


const description_supports = """Global constraint ensuring that `x` is in the set of configurations given by `pair_vars`: `x ∈ pair_vars`"""

@usual concept_supports(x; pair_vars) = xcsp_extension(list = x, supports = pair_vars)

const description_conflicts = """Global constraint ensuring that `x` is not in the set of configurations given by `pair_vars`: `x ∉ pair_vars`"""

@usual concept_conflicts(x; pair_vars) = xcsp_extension(list = x, conflicts = pair_vars)
