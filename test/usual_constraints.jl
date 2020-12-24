for (name, c) in usual_constraints
    @info "testing $name"
    for i in 1:10
        x = rand(1:10,5)
        @test concept(c, x...) ? (error_f(c, x...) == 0.0) : (error_f(c, x...) > 0.0)
    end
end