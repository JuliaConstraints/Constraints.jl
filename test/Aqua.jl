@testset "Aqua.jl" begin
    import Aqua
    import Constraints

    # TODO: Fix the broken tests and remove the `broken = true` flag
    Aqua.test_all(
        Constraints;
        ambiguities = (broken = true,),
        deps_compat = false,
        piracies = (broken = true,),
        unbound_args = (broken = false)
    )

    @testset "Ambiguities: Constraints" begin
        # Aqua.test_ambiguities(Constraints;)
    end

    @testset "Piracies: Constraints" begin
        # Aqua.test_piracies(Constraints;)
    end

    @testset "Dependencies compatibility (no extras)" begin
        Aqua.test_deps_compat(
            Constraints;
            check_extras = false            # ignore = [:Random]
        )
    end

    @testset "Unbound type parameters" begin
        # Aqua.test_unbound_args(Constraints;)
    end
end
