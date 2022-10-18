using CompositionalNetworks
using ConstraintDomains
using ConstraintLearning
using Constraints

# FIXME - Commented concept have a new name
const DEFAULT_TARGETS = Dict(
    :all_different => Dict(
        :domains => [domain(1:4) for i in 1:4],
    ),
    :all_equal => Dict(
        :domains => [domain(1:4) for i in 1:4],
    ),
    :all_equal_param => Dict(
        :domains => [domain(8:12) for i in 1:4],
        :param => 10,
    ),
    :dist_different => Dict(
        :domains => [domain(1:4) for i in 1:4],
    ),
    :eq => Dict(
        :domains => [domain(1:10) for i in 1:2],
    ),
    # :less_than_param => Dict(
    #     :domains => [domain(0:4) for i in 1:1],
    #     :param => 2,
    # ),
    # :minus_equal_param => Dict(
    #     :domains => [domain(0:4) for i in 1:2],
    #     :param => 3,
    # ),
    :ordered => Dict(
        :domains => [domain(1:4) for i in 1:4],
    ),
    # :sequential_tasks => Dict(
    #     :domains => [domain(1:4) for i in 1:4],
    # ),
    # :sum_equal_param => Dict(
    #     :domains => [domain(1:9) for i in 1:3],
    #     :param => 15,
    # ),
)

const DEFAULT_CONFIG = Dict(
    :lang => :Julia,
    :local_iter => 100,
    :global_iter => 100,
    :search => :complete,
    :metric => hamming,
    :population => 400,
)

const DEFAULT_PATH = joinpath(dirname(pathof(Constraints)), "compositions")

function learn_from_icn(;
    targets=DEFAULT_TARGETS,
    config=DEFAULT_CONFIG,
    path=DEFAULT_PATH
)
    optimizer = ICNGeneticOptimizer(;
        global_iter=config[:global_iter],
        local_iter=config[:local_iter],
        pop_size=config[:population]
    )
    for t in targets
        @info "Starting learning for $(t.first)"
        con = concept(usual_constraints[t.first])
        domains = t.second[:domains]
        param = get(t.second, :param, nothing)
        settings = ExploreSettings(domains; search=config[:search])
        configurations = explore(domains, con; param, settings)
        name = "icn_$(t.first)"
        compose_to_file!(
            con,
            name,
            joinpath(path, "$name.jl");
            configurations,
            domains,
            optimizer,
            param,
            metric=config[:metric]
        )
        println()
    end

end

learn_from_icn()
