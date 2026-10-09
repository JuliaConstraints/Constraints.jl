@testset "Aqua.jl" begin
    import Aqua
    import Constraints

    Aqua.test_all(
        Constraints;
        ambiguities = (broken = false,),
        deps_compat = false,
        piracies = (broken = false,),
        unbound_args = (broken = false,)
    )

    @testset "Dependencies compatibility (no extras)" begin
        Aqua.test_deps_compat(
            Constraints;
            check_extras = false            # ignore = [:Random]
        )
    end

end
