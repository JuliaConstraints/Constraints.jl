##!NOTE - constraints of type extension represent a list of supported or conflicted tuples

# TODO - Better input for conflicts and supports (cf XCSP3-core)

const description_extension = """
Global constraint enforcing that the tuple `x` matches a configuration within the supports set `pair_vars[1]` or does not match any configuration within the conflicts set `pair_vars[2]`. It embodies the logic: `x ∈ pair_vars[1] || x ∉ pair_vars[2]`, providing a comprehensive way to define valid (supported) and invalid (conflicted) tuples for constraint satisfaction problems. This constraint is versatile, allowing for the explicit delineation of both acceptable and unacceptable configurations.
"""

const description_supports = """
Global constraint ensuring that the tuple `x` matches a configuration listed within the support set `pair_vars`. This constraint is derived from the extension model, specifying that `x` must be one of the explicitly defined supported configurations: `x ∈ pair_vars`. It is utilized to directly declare the tuples that are valid and should be included in the solution space.
"""

const description_conflicts = """
Global constraint ensuring that the tuple `x` does not match any configuration listed within the conflict set `pair_vars`. This constraint, originating from the extension model, stipulates that `x` must avoid all configurations defined as conflicts: `x ∉ pair_vars`. It is useful for specifying tuples that are explicitly forbidden and should be excluded from the solution space.
"""

xcsp_extension(list, ::Nothing, conflicts) = list ∉ conflicts
xcsp_extension(list, supports, _) = list ∈ supports

"""
    xcsp_extension(; list, supports=nothing, conflicts=nothing)

$description_extension

## Arguments
- `list::Vector{Int}`: A list of variables
- `supports::Vector{Vector{Int}}`: A set of supported tuples. Default to nothing.
- `conflicts::Vector{Vector{Int}}`: A set of conflicted tuples. Default to nothing.

## Instantiations
- `:extension`: $description_extension
- `:supports`: $description_supports
- `:conflicts`: $description_conflicts

## Examples
```julia
c = USUAL_CONSTRAINTS[:extension] |> concept
c([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])
c([1, 2, 3, 4, 5]; pair_vars=([[1, 2, 3, 4, 5]], [[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]]))
c([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])

c = concept(USUAL_CONSTRAINTS[:supports])
c([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 3, 4, 5]])

c = concept(USUAL_CONSTRAINTS[:conflicts])
c([1, 2, 3, 4, 5]; pair_vars=[[1, 2, 1, 4, 5], [1, 2, 3, 5, 5]])
```

````@ansi test
2 + 2
````

"""
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

@usual concept_extension(x; pair_vars) = concept_extension(x, pair_vars)

@usual concept_supports(x; pair_vars) = xcsp_extension(list = x, supports = pair_vars)

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