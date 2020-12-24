using Constraints
using Test

@testset "Constraints.jl" begin

# Empty constraint
c = Constraint()
@test c.concept(1) == true
@test c.error(1) == 0.0

end
