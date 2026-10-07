#!SECTION - nValues

const description_nvalues = """
Ensures that the number of distinct values in `x` satisfies a given numerical condition. 
The constraint is defined by the following expression: `nValues(x, op, val)` where `x` is a list of variables, `op` is a comparison operator, and `val` is an integer value.
"""

"""
    xcsp_nvalues(list, condition, except)

Return `true` if the number of distinct values in `list` satisfies the given condition, `false` otherwise.

## Arguments
- `list::Vector{Int}`: list of values to check.
- `condition`: condition to satisfy.
- `except::Union{Nothing, Vector{Int}}`: list of values to exclude. Default is `nothing`.

## Variants
- `:nvalues`: $description_nvalues
```julia
concept(:nvalues, x; op, val)
concept(:nvalues)(x; op, val)
```

## Examples
```julia
c = concept(:nvalues)

c([1, 2, 3, 4, 5]; op = ==, val = 5)
c([1, 2, 3, 4, 5]; op = ==, val = 2)
c([1, 2, 3, 4, 3]; op = <=, val = 5)
c([1, 2, 3, 4, 3]; op = <=, val = 3)
```
"""
function xcsp_nvalues(list, condition, except)
    return condition[1](_nvalues_count(list, except), condition[2])
end

function _nvalues_count(list, except)
    distinct = Set{eltype(list)}()
    for value in list
        (isnothing(except) || value ∉ except) && push!(distinct, value)
    end
    return length(distinct)
end

xcsp_nvalues(; list, condition, except = nothing) = xcsp_nvalues(list, condition, except)

@usual function concept_nvalues(x; op = ==, val, vals = nothing)
    return xcsp_nvalues(list = x, condition = (op, val), except = vals)
end

@testitem "nValues" tags=[:usual, :constraints, :nvalues] begin
    c = USUAL_CONSTRAINTS[:nvalues] |> concept
    e = USUAL_CONSTRAINTS[:nvalues] |> error_f
    vs = Constraints.concept_vs_error

    @test c([1, 2, 3, 4, 5]; op = ==, val = 5)
    @test !c([1, 2, 3, 4, 5]; op = ==, val = 2)
    @test c([1, 2, 3, 4, 3]; op = <=, val = 5)
    @test !c([1, 2, 3, 4, 3]; op = <=, val = 3)

    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 5]; op = ==, val = 2)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 5)
    @test vs(c, e, [1, 2, 3, 4, 3]; op = <=, val = 3)
end

@testitem "nValues generic filtered inputs" tags=[:nvalues] begin
    for except in (nothing, Int[], [0], [0, 1, 2]), n in (0, 1, 3)
        for tuple in Iterators.product(ntuple(_ -> 0:2, n)...)
            vector = collect(tuple)
            padded = [9; vector; 9]
            view_input = view(padded, 2:(n + 1))
            filtered = Iterators.filter(_ -> true, vector)
            for input in (vector, view_input, filtered)
                expected = length(Set(v for v in vector if isnothing(except) || v ∉ except))
                @test Constraints._nvalues_count(input, except) == expected
                for target in 0:3, op in (==, !=, <, <=, >, >=)
                    @test Constraints.xcsp_nvalues(input, (op, target), except) == op(expected, target)
                    @test iszero(Constraints.penalty_f(:nvalues, :value)(input;
                        vals = except, val = target, op)) == op(expected, target)
                end
            end
        end
    end
end
