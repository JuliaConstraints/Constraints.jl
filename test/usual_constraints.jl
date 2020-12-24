for (name, c) in usual_constraints
    @info "testing $name"
    for i in 1:10
        al = args_length(c)
        x = rand(1:10, isnothing(al) ? 5 : al)

        pl = params_length(c)
        y = rand(1:10, isnothing(pl) ? 5 : pl)

        c_concept = pl == 0 ? concept(c, x...) : concept(c, x...; param = y)
        c_error_f = pl == 0 ? error_f(c, x...) : error_f(c, x...; param = y)

        @test c_concept ? (c_error_f == 0.0) : (c_error_f > 0.0)
    end
end