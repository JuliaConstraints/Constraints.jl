using Constraints
using ConstraintDomains
using CompositionalNetworks
using Test

@testset "Constraints.jl" begin

    @testset "Empty constraint" begin
        c = Constraint()
        @test concept(c, []) == true
        @test error_f(c, []) == 0.0
    end

    # Test on usual_constraints
    include("usual_constraints.jl")

end
