using Constraints
using CompositionalNetworks
using Test

@testset "Constraints.jl" begin

# Empty constraint
c = Constraint()
@test concept(c, []) == true
@test error_f(c, []) == 0.0

# Test on usual_constraints
include("usual_constraints.jl")

end
