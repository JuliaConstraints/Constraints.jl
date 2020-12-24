using Constraints
using Test

@testset "Constraints.jl" begin

# Empty constraint
c = Constraint()
@test concept(c, 1) == true
@test error_f(c, 1) == 0.0

# Test on usual_constraints
include("usual_constraints.jl")

end
