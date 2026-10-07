"""
    USUAL_CONSTRAINTS::Dict
Dictionary that contains all the usual constraints defined in Constraint.jl. It is based on XCSP3-core specifications available at https://arxiv.org/abs/2009.00514

Adding a new constraint is as simple as defining a new function with the same name as the constraint and using the `@usual` macro to define it. The macro will take care of adding the new constraint to the `USUAL_CONSTRAINTS` dictionary.

## Example
```julia
@usual concept_all_different(x; vals=nothing) = xcsp_all_different(list=x, except=vals)
```
"""
const USUAL_CONSTRAINTS = Dict{Symbol, Constraint}()

"""Versioned semantic description layered over a compatible `Constraint` implementation."""
struct ConstraintSpec{C <: Constraint}
    identity::Symbol
    version::VersionNumber
    implementation::C
    schemas::Vector{Dict{Symbol, Bool}}
    capabilities::NamedTuple
    external_names::NamedTuple
end

"""Versioned semantic specifications indexed by stable constraint identity."""
const CONSTRAINT_SPECS = Dict{Symbol, Vector{ConstraintSpec}}()

function _xcsp3_name(identity::Symbol)
    parts = split(String(identity), '_')
    return first(parts) * join(uppercasefirst.(parts[2:end]))
end

"""Register one version of a constraint's semantic schema and capabilities."""
function register_constraint_spec!(identity::Symbol, implementation::Constraint;
        version::VersionNumber = v"1.0.0", schemas = implementation.params,
        capabilities = (parse = true, solve = true, validate = true,
            incremental = supports_incremental(error_f(implementation))),
        external_names = (xcsp3 = _xcsp3_name(identity), catalog = String(identity)))
    versions = get!(CONSTRAINT_SPECS, identity, ConstraintSpec[])
    any(spec -> spec.version == version, versions) &&
        throw(ArgumentError("constraint :$identity already has specification version $version"))
    spec = ConstraintSpec(identity, version, implementation,
        [copy(schema) for schema in schemas], capabilities, external_names)
    push!(versions, spec)
    sort!(versions; by = spec -> spec.version)
    return spec
end

function _register_constraint_schema!(identity, implementation, schema)
    versions = get(CONSTRAINT_SPECS, identity, nothing)
    if isnothing(versions)
        register_constraint_spec!(identity, implementation; schemas = [schema])
    else
        spec = only(filter(candidate -> candidate.version == v"1.0.0", versions))
        push!(spec.schemas, copy(schema))
    end
    return nothing
end

"""Return the latest, or an explicitly versioned, semantic specification."""
function constraint_spec(identity::Symbol; version::Union{Nothing, VersionNumber} = nothing)
    versions = get(CONSTRAINT_SPECS, identity, nothing)
    isnothing(versions) && throw(KeyError(identity))
    isnothing(version) && return last(versions)
    index = findfirst(spec -> spec.version == version, versions)
    isnothing(index) && throw(KeyError((identity, version)))
    return versions[index]
end

"""Return the stable semantic identity of a specification or registered symbol."""
semantic_id(spec::ConstraintSpec) = spec.identity
semantic_id(identity::Symbol) = constraint_spec(identity).identity

function _refresh_constraint_spec_capabilities!()
    for versions in values(CONSTRAINT_SPECS), index in eachindex(versions)
        spec = versions[index]
        capabilities = merge(spec.capabilities,
            (incremental = supports_incremental(error_f(spec.implementation)),))
        versions[index] = ConstraintSpec(spec.identity, spec.version, spec.implementation,
            spec.schemas, capabilities, spec.external_names)
    end
    return nothing
end

"""
    describe(constraints::Dict{Symbol,Constraint}=USUAL_CONSTRAINTS; width=150)

Return a pretty table with the description of the constraints in `constraints`.

## Arguments
- `constraints::Dict{Symbol,Constraint}`: dictionary of constraints to describe. Default is `USUAL_CONSTRAINTS`.
- `width::Int`: width of the table.

## Example
```julia
describe()
```
"""
function describe(constraints::Dict{Symbol, Constraint} = USUAL_CONSTRAINTS; width = 150)
    df = DataFrame(; Names = Symbol[], Description = String[])
    for (name, cons) in constraints
        push!(df, (name, cons.description))
    end
    l = maximum(length ∘ string, keys(USUAL_CONSTRAINTS))
    dl = maximum(c -> length(string(c.description)), values(USUAL_CONSTRAINTS))
    return pretty_table(
        df;
        columns_width = [l, min(dl, width - l)],
        linebreaks = true,
        autowrap = true,
        alignment = :l
    )
end

describe(s::Symbol) = USUAL_CONSTRAINTS[s].description

"""
    extract_parameters(s::Symbol, constraints_dict=USUAL_CONSTRAINTS; parameters=ConstraintCommons.USUAL_CONSTRAINT_PARAMETERS)

Return the parameters of the constraint `s` in `constraints_dict`.

## Arguments
- `s::Symbol`: the constraint name.
- `constraints_dict::Dict{Symbol,Constraint}`: dictionary of constraints. Default is `USUAL_CONSTRAINTS`.
- `parameters::Vector{Symbol}`: vector of parameters. Default is `ConstraintCommons.USUAL_CONSTRAINT_PARAMETERS`.

## Example
```julia
extract_parameters(:all_different)
```
"""
function extract_parameters(
        s::Symbol,
        constraints_dict = USUAL_CONSTRAINTS;
        parameters = ConstraintCommons.USUAL_CONSTRAINT_PARAMETERS
)
    return ConstraintCommons.extract_parameters(concept(constraints_dict[s]); parameters)
end

function extract_parameters(f::Function; parameters = USUAL_CONSTRAINT_PARAMETERS)
    return ConstraintCommons.extract_parameters(f; parameters)
end

"""
    usual(ex::Expr)

This macro is used to define a new constraint or update an existing one in the USUAL_CONSTRAINTS dictionary. It takes an expression ex as input, which represents the definition of a constraint.

Here's a step-by-step explanation of what the macro does:
1. It first extracts the symbol of the concept from the input expression. This symbol is expected to be the first argument of the first argument of the expression. For example, if the expression is @usual all_different(x; y=1), the symbol would be :all_different.
2. It then calls the shrink_concept function on the symbol to get a simplified version of the concept symbol.
3. It initializes a dictionary defaults to store whether each keyword argument of the concept has a default value or not.
4. It checks if the expression has more than two arguments. If it does, it means that there are keyword arguments present. It then loops over these keyword arguments. If a keyword argument is a symbol, it means it doesn't have a default value, so it adds an entry to the defaults dictionary with the keyword argument as the key and false as the value. If a keyword argument is not a symbol, it means it has a default value, so it adds an entry to the defaults dictionary with the keyword argument as the key and true as the value.
5. It calls the make_error function on the simplified concept symbol to generate an error function for the constraint.
6. It evaluates the input expression to get the concept function.
7. It checks if the USUAL_CONSTRAINTS dictionary already contains an entry for the simplified concept symbol. If it does, it adds the defaults dictionary to the parameters of the existing constraint. If it doesn't, it creates a new constraint with the concept function, a description, the error function, and the defaults dictionary as the parameters, and adds it to the USUAL_CONSTRAINTS dictionary.

This macro is used to make it easier to define and update constraints in a consistent and possibly automated way.

## Arguments
- `ex::Expr`: expression to parse.

## Example
```julia
@usual concept_all_different(x; vals=nothing) = xcsp_all_different(list=x, except=vals)
```
"""
macro usual(ex::Expr)
    # Symbol of the concept, for instance :all_different
    s = ex.args[1].args[1]
    c = shrink_concept(s)

    # Dict storing the existence or not of a default value for each kwarg
    defaults = Dict{Symbol, Bool}()

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

    concept = eval(ex)
    error = make_error(c, concept)
    if haskey(USUAL_CONSTRAINTS, c)
        push!(USUAL_CONSTRAINTS[c].params, defaults)
    else # Enter new constraint
        ds = symcon(:description, c)
        description = isdefined(Constraints, ds) ? getfield(Constraints, ds) :
                      "No given description!"

        params = [defaults]
        cons = Constraint(; concept, description, error, params)

        push!(USUAL_CONSTRAINTS, c => cons)
    end

    _register_constraint_schema!(c, USUAL_CONSTRAINTS[c], defaults)

    return nothing
end

"""
    constraints_parameters(C=USUAL_CONSTRAINTS)

Return a pretty table with the parameters of the constraints in `C`.

## Arguments
- `C::Dict{Symbol,Constraint}`: dictionary of constraints. Default is `USUAL_CONSTRAINTS`.

## Example
```julia
constraints_parameters()
```
"""
function constraints_parameters(C = USUAL_CONSTRAINTS)
    df = DataFrame(
        Constraint = Symbol[],
        bool = String[],
        dim = String[],
        id = String[],
        language = String[],
        op = String[],
        pair_vars = String[],
        val = String[],
        vals = String[]
    )

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
        f = (data, i, j) -> i % 2 == 0,
        crayon = Crayon(background = :light_blue, foreground = :black)
    )

    return pretty_table(
        df;
        highlighters = hl_odd,
        header_crayon = crayon"yellow bold",
        title = "Available parameters per constraint (× -> required, o -> optional)",
        show_subheader = false,
        crop = :none
    )
end

@testitem "Versioned semantic constraint registry" tags=[:usual, :registry] begin
    import Test: @test, @test_throws

    all_different = constraint_spec(:all_different)
    sum_spec = constraint_spec(:sum; version = v"1.0.0")
    no_overlap = constraint_spec(:no_overlap)
    @test semantic_id(all_different) == :all_different
    @test all_different.external_names.xcsp3 == "allDifferent"
    @test any(schema -> get(schema, :val, true) == false, sum_spec.schemas)
    @test no_overlap.external_names.xcsp3 == "noOverlap"
    @test no_overlap.capabilities.incremental
    @test all(spec -> spec.capabilities.parse && spec.capabilities.solve &&
                      spec.capabilities.validate,
        (all_different, sum_spec, no_overlap))
    @test_throws KeyError constraint_spec(:not_registered)
    @test_throws KeyError constraint_spec(:sum; version = v"99.0.0")
end

"""
    constraints_descriptions(C=USUAL_CONSTRAINTS)

Return a pretty table with the descriptions of the constraints in `C`.

## Arguments
- `C::Dict{Symbol,Constraint}`: dictionary of constraints. Default is `USUAL_CONSTRAINTS`.

## Example
```julia
constraints_descriptions()
```
"""
function constraints_descriptions(C = USUAL_CONSTRAINTS)
    df = DataFrame(Constraint = Symbol[], Description = String[])

    for (s, c) in C
        push!(df, [s, c.description])
    end

    sort!(df)

    hl_odd = Highlighter(
        f = (data, i, j) -> i % 2 == 0,
        crayon = Crayon(background = :light_blue)
    )

    return pretty_table(
        df;
        # highlighters = hl_odd,
        header_crayon = crayon"yellow bold",
        autowrap = true,
        linebreaks = true,
        columns_width = [0, 80],
        hlines = :all,
        alignment = :l,
        show_subheader = false,
        crop = :none
    )
end

"""
    concept(s::Symbol, args...; kargs...)

Return the concept of the constraint `s` applied to `args` and `kargs`. This is a shortcut for `concept(USUAL_CONSTRAINTS[s])(args...; kargs...)`.

## Arguments
- `s::Symbol`: the constraint name.
- `args...`: the arguments to apply the concept to.
- `kargs...`: the keyword arguments to apply the concept to.

## Example
```julia
concept(:all_different, [1, 2, 3])
```
"""
concept(s::Symbol, args...; kargs...) = concept(USUAL_CONSTRAINTS[s])(args...; kargs...)
concept(s::Symbol) = concept(USUAL_CONSTRAINTS[s])

## SECTION - Test Items
@testitem "Usual constraints" tags=[:usual, :constraints] default_imports=false begin
    using ConstraintDomains
    using Constraints
    using Test

    import Constraints: concept_vs_error

    domains = fill(domain(0:3), 4)
    dom_bool = fill(domain([false, true]), 4)

    for (name, c) in USUAL_CONSTRAINTS
        for _ in 1:1000
            for (id, method_params) in enumerate(extract_parameters(c.concept))
                params = Dict(
                    map(p -> (p => rand(generate_parameters(domains, p))), method_params),
                )
                x = rand(
                    occursin("Bool", Base.arg_decl_parts(methods(c.concept)[id])[2][2][2]) ?
                    dom_bool : domains,
                )
                @test concept_vs_error(c.concept, c.error, x; params...)
            end
        end
        symmetries(c)
    end
end
