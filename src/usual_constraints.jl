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
        alignment=:l
    )
end

function ConstraintCommons.extract_parameters(
    s::Symbol,
    constraints_dict=USUAL_CONSTRAINTS;
    parameters=ConstraintCommons.USUAL_CONSTRAINT_PARAMETERS
)
    return ConstraintCommons.extract_parameters(concept(constraints_dict[s]); parameters)
end

macro usual(ex::Expr)
    # Symbol of the concept, for instance :all_different
    s = ex.args[1].args[1]
    c = shrink_concept(s)

    # Dict storing the existence or not of a default value for each kwarg
    defaults = Dict{Symbol,Bool}()

    # Check if a `;` is present in the call, then loop over kwargs
    if length(ex.args[1].args) > 2
        for kwarg in ex.args[1].args[2].args
            if isa(kwarg, Symbol)
                push!(defaults, kwarg => false)
            else
                push!(defaults, kwarg.args[1] => true)
            end
        end
    end


    error = make_error(c)
    concept = eval(ex)
    if haskey(USUAL_CONSTRAINTS, c)
        push!(USUAL_CONSTRAINTS[c].params, defaults)
    else # Enter new constraint
        ds = :description * c
        description = isdefined(Constraints, ds) ? eval(ds) : "No given description!"

        params = [defaults]
        cons = Constraint(; concept, description, error, params)

        push!(USUAL_CONSTRAINTS, c => cons)
    end

    return nothing
end

function constraints_parameters(C=USUAL_CONSTRAINTS)
    df = DataFrame(Constraint=Symbol[], bool=String[], dim=String[], id=String[], language=String[], op=String[], pair_vars=String[], val=String[], vals=String[])

    for (s, c) in C
        base = vcat([s], fill("", length(USUAL_CONSTRAINT_PARAMETERS)))
        for P in c.params
            push!(df, base)
            for (p, b) in P
                df[end, p] = b == 1 ? "o" : "×"
            end
        end
    end

    sort!(df)

    hl_odd = Highlighter(
        f=(data, i, j) -> i % 2 == 0,
        crayon=Crayon(background=:light_blue, foreground=:black),
    )

    return pretty_table(
        df;
        highlighters=hl_odd,
        header_crayon=crayon"yellow bold",
        title="Available parameters per constraint (× -> required, o -> optional)",
        show_subheader=false,
        crop=:none
    )
end

function constraints_descriptions(C=USUAL_CONSTRAINTS)
    df = DataFrame(Constraint=Symbol[], Description=String[])

    for (s, c) in C
        push!(df, [s, c.description])
    end

    sort!(df)

    hl_odd = Highlighter(
        f=(data, i, j) -> i % 2 == 0,
        crayon=Crayon(background=:light_blue),
    )

    return pretty_table(
        df;
        # highlighters = hl_odd,
        header_crayon=crayon"yellow bold",
        autowrap=true,
        linebreaks=true,
        columns_width=[0, 80],
        hlines=:all,
        alignment=:l,
        show_subheader=false,
        crop=:none
    )
end

## SECTION - Test Items
@testitem "Usual constraints" tags = [:usual, :constraints] default_imports = false begin
    using ConstraintDomains
    using Constraints
    using Test

    import Constraints: concept_vs_error

    domains = fill(domain(0:3), 4)
    dom_bool = fill(domain([false, true]), 4)

    for (name, c) in USUAL_CONSTRAINTS
        for _ in 1:000
            for (id, method_params) in enumerate(extract_parameters(c.concept))
                params = Dict(
                    map(p -> (p => rand(generate_parameters(domains, p))), method_params)
                )
                x = rand(occursin("Bool", Base.arg_decl_parts(methods(c.concept)[id])[2][2][2]) ? dom_bool : domains)
                @test concept_vs_error(c.concept, c.error, x; params...)
            end
        end
        symmetries(c)
    end
end
