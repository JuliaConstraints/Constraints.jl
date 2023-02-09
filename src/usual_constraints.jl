"""
    USUAL_CONSTRAINTS::Dict
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
const USUAL_CONSTRAINTS = Dict{Symbol,Constraint}(:always_true => Constraint())

function describe(constraints::Dict{Symbol,Constraint}=USUAL_CONSTRAINTS; width=150)
    df = DataFrame(; Names=Symbol[], Description=String[])
    for (name, cons) in constraints
        push!(df, (name, cons.description))
    end
    l = maximum(length ∘ string, keys(USUAL_CONSTRAINTS))
    dl = maximum(c -> length(string(c.description)), values(USUAL_CONSTRAINTS))
    return pretty_table(
        df;
        columns_width=[l, min(dl, width - l)],
        linebreaks=true,
        autowrap=true,
        alignment=:l,
    )
end

function ConstraintCommons.extract_parameters(
    s::Symbol,
    constraints_dict = USUAL_CONSTRAINTS;
    parameters = ConstraintCommons.USUAL_CONSTRAINT_PARAMETERS,
)
    return ConstraintCommons.extract_parameters(concept(constraints_dict[s]); parameters)
end
