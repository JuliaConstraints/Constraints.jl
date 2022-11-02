domains = fill(domain(0:3), 4)
dom_bool = fill(domain([false, true]), 4)

for (name, c) in usual_constraints
    @testset "Constraint: $name" begin
        @info "Testing $name"
        for _ in 1:10000
            for (id, method_params) in enumerate(extract_parameters(c.concept))
                params = Dict(
                    map(p -> (p => rand(generate_parameters(domains, p))), method_params)
                )
                x = rand(occursin("Bool", Base.arg_decl_parts(methods(c.concept)[id])[2][2][2]) ? dom_bool : domains)
                @test (c.error(x; params...) > 0.0) != c.concept(x; params...)
            end
        end
        symmetries(c)
    end
end
