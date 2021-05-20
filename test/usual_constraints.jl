for (name, c) in usual_constraints
    @info "testing $name"
    for i in 1:10
        al = args_length(c)
        x = rand(1:10, isnothing(al) ? 5 : al)

        pl = params_length(c)
        y_aux = rand(1:10, isnothing(pl) ? 5 : pl)
        y = length(y_aux) == 1 ? first(y_aux) : y_aux

        ds = 10

        c_concept = pl == 0 ? concept(c, x) : concept(c, x; param = y)
        c_error_f = pl == 0 ? error_f(c, x; dom_size = ds) : error_f(c, x; param = y, dom_size = ds)

        @test c_concept ? (c_error_f == 0.0) : (c_error_f > 0.0)
    end
    symmetries(c)
end