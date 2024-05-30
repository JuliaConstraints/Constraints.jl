# cardinality (or global_cardinality or gcc)

const description_cardinality = """
The cardinality constraint, also known as the global cardinality constraint (GCC), is a constraint in constraint programming that restricts the number of times a value can appear in a set of variables.
"""
const description_cardinality_closed = """
The closed cardinality constraint, also known as the global cardinality constraint (GCC), is a constraint in constraint programming that restricts the number of times a value can appear in a set of variables. It is closed, meaning that all values in the domain of the variables must be considered.
"""

const description_cardinality_open = """
The open cardinality constraint, also known as the global cardinality constraint (GCC), is a constraint in constraint programming that restricts the number of times a value can appear in a set of variables. It is open, meaning that only the values in the list of values must be considered.
"""

"""
    xcsp_cardinality(list, values, occurs, closed)

Return `true` if the number of occurrences of the values in `values` in `list` satisfies the given condition, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `values::Vector{Int}`: list of values to check.
- `occurs::Vector{Int}`: list of occurrences to check.
- `closed::Bool`: whether the constraint is closed or not.

## Variants
- `:cardinality`: $description_cardinality
```julia
concept(:cardinality, x; bool=false, vals)
concept(:cardinality)(x; bool=false, vals)
```
- `:cardinality_closed`: $description_cardinality_closed
```julia
concept(:cardinality_closed, x; vals)
concept(:cardinality_closed)(x; vals)
```
- `:cardinality_open`: $description_cardinality_open
```julia
concept(:cardinality_open, x; vals)
concept(:cardinality_open)(x; vals)
```

## Examples
```julia
c = concept(:cardinality)

c([2, 5, 10, 10]; vals=[2 0 1; 5 1 3; 10 2 3])
c([8, 5, 10, 10]; vals=[2 0 1; 5 1 3; 10 2 3], bool=false)
c([8, 5, 10, 10]; vals=[2 0 1; 5 1 3; 10 2 3], bool=true)
c([2, 5, 10, 10]; vals=[2 1; 5 1; 10 2])
c([2, 5, 10, 10]; vals=[2 0 1 42; 5 1 3 7; 10 2 3 -4])
c([2, 5, 5, 10]; vals=[2 0 1; 5 1 3; 10 2 3])
c([2, 5, 10, 8]; vals=[2 1; 5 1; 10 2])
c([5, 5, 5, 10]; vals=[2 0 1 42; 5 1 3 7; 10 2 3 -4])

cc = concept(:cardinality_closed)
cc([8, 5, 10, 10]; vals=[2 0 1; 5 1 3; 10 2 3])

co = concept(:cardinality_open)
co([8, 5, 10, 10]; vals=[2 0 1; 5 1 3; 10 2 3])
```
"""
function xcsp_cardinality(; list, values, occurs, closed = false)
    counts = zeros(Int, Indices(distinct(values)))
    for t in list
        if t ∉ values
            closed && (return false)
            continue
        else
            incsert!(counts, t)
        end
    end
    for (id, v) in enumerate(values)
        counts[v] ∈ occurs[id] || (return false)
    end
    return true
end

@usual function concept_cardinality(x; bool = false, vals)
    values = vals[:, 1]
    occurs = if size(vals, 2) == 1
        ones(Int, size(vals, 1))
    elseif size(vals, 2) ≥ 3
        map(i -> vals[i, 2]:(vals[i, 2] ≤ vals[i, 3] ? 1 : -1):(vals[i, 3]),
            1:size(vals, 1))
    else
        vals[:, 2]
    end
    return xcsp_cardinality(; list = x, values, occurs, closed = bool)
end

@usual concept_cardinality_closed(x; vals) = concept_cardinality(x; bool = true, vals)
@usual concept_cardinality_open(x; vals) = concept_cardinality(x; bool = false, vals)

## SECTION - Test Items
@testitem "Cardinality" tags=[:usual, :constraints, :cardinality] begin
    c = USUAL_CONSTRAINTS[:cardinality] |> concept
    e = USUAL_CONSTRAINTS[:cardinality] |> error_f
    vs = Constraints.concept_vs_error

    @test c([2, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3])
    @test c([8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3], bool = false)
    @test !c([8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3], bool = true)
    @test c([2, 5, 10, 10]; vals = [2 1; 5 1; 10 2])
    @test c([2, 5, 10, 10]; vals = [2 0 1 42; 5 1 3 7; 10 2 3 -4])
    @test !c([2, 5, 5, 10]; vals = [2 0 1; 5 1 3; 10 2 3])
    @test !c([2, 5, 10, 8]; vals = [2 1; 5 1; 10 2])
    @test !c([5, 5, 5, 10]; vals = [2 0 1 42; 5 1 3 7; 10 2 3 -4])

    @test vs(c, e, [2, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3])
    @test vs(c, e, [8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3], bool = false)
    @test vs(c, e, [8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3], bool = true)
    @test vs(c, e, [2, 5, 10, 10]; vals = [2 1; 5 1; 10 2])
    @test vs(c, e, [2, 5, 10, 10]; vals = [2 0 1 42; 5 1 3 7; 10 2 3 -4])
    @test vs(c, e, [2, 5, 5, 10]; vals = [2 0 1; 5 1 3; 10 2 3])
    @test vs(c, e, [2, 5, 10, 8]; vals = [2 1; 5 1; 10 2])
    @test vs(c, e, [5, 5, 5, 10]; vals = [2 0 1 42; 5 1 3 7; 10 2 3 -4])

    cc = USUAL_CONSTRAINTS[:cardinality_closed] |> concept
    ec = USUAL_CONSTRAINTS[:cardinality_closed] |> error_f
    @test cc([8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3]) ==
          c([8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3], bool = true)
    @test vs(cc, ec, [8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3])

    co = USUAL_CONSTRAINTS[:cardinality_open] |> concept
    eo = USUAL_CONSTRAINTS[:cardinality_open] |> error_f
    @test co([8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3]) ==
          c([8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3], bool = false)
    @test vs(co, eo, [8, 5, 10, 10]; vals = [2 0 1; 5 1 3; 10 2 3])
end
