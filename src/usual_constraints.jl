"""
    usual_constraints::Dict
Dictionary that contains all the usual constraints defined in Constraint.jl. It is based on XCSP3-core specifications available at https://arxiv.org/abs/2009.00514

Adding a new constraint is as simple as
```julia
@usual name p a sym₁ sym₂
```
where
- `name`: constraint name
- `p`: the length of the parameters (0 means no parameters)
- `a`: the length of the arguments/variables (0 means any length is possible).
- `symᵢ`: a sequence of symmetries (can be left empty)

Both `a` alone, or `p` and `a` together are optional.

Note that `concept_name` needs to be defined. Unless both `error_name` and `icn_error_name` are defined, a default error function will be computed.
Please (re-)define `error_name` for a hand_made error function.
"""
const usual_constraints = Dict{Symbol,Constraint}(:always_true => Constraint())

function describe(constraints::Dict{Symbol,Constraint}=usual_constraints; width=150)
    df = DataFrame(; Names=Symbol[], Description=String[])
    for (name, cons) in constraints
        push!(df, (name, cons.description))
    end
    l = maximum(length ∘ string, keys(usual_constraints))
    dl = maximum(c -> length(string(c.description)), values(usual_constraints))
    return pretty_table(
        df;
        columns_width=[l, min(dl, width - l)],
        linebreaks=true,
        autowrap=true,
        alignment=:l,
    )
end
