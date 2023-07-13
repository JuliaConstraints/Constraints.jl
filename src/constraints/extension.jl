##!NOTE - constraints of type extension represent a list of supported or conflicted tuples

# TODO - Better input for conflicts and supports (cf XCSP3-core)

xcsp_extension(list, ::Nothing, conflicts) = list ∉ conflicts
xcsp_extension(list, supports, _) = list ∈ supports

function xcsp_extension(; list, supports=nothing, conflicts=nothing)
    return xcsp_extension(list, supports, conflicts)
end

function concept_extension(x, pair_vars::Vector{Vector{T}}) where {T <: Number}
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

@testitem "Extension" tags = [:usual, :constraints, :extension] begin
    c = USUAL_CONSTRAINTS[:extension] |> concept
    e = USUAL_CONSTRAINTS[:extension] |> error_f
    c_supports = USUAL_CONSTRAINTS[:supports] |> concept
    e_supports = USUAL_CONSTRAINTS[:supports] |> error_f
    c_conflicts = USUAL_CONSTRAINTS[:conflicts] |> concept
    e_conflicts = USUAL_CONSTRAINTS[:conflicts] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])
    @test c([1, 2, 3, 4, 5]; pair_vars=([[1, 2, 3, 4, 5]], [[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]]))
    @test !c([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])
    @test c_supports([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])
    @test !c_supports([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])
    @test c_conflicts([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])
    @test !c_conflicts([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])

    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])
    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars=([[1, 2, 3, 4, 5]], [[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]]))
    @test vs(c, e, [1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])
    @test vs(c_supports, e_supports, [1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])
    @test vs(c_supports, e_supports, [1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])
    @test vs(c_conflicts, e_conflicts, [1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])
    @test vs(c_conflicts, e_conflicts, [1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])
end