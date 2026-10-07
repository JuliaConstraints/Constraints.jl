using Test
using TestItemRunner
using TestItems

@testset "Package tests: Constraints" begin
    include("Aqua.jl")
    include("TestItemRunner.jl")
end
