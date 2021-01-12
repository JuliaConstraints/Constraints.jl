using ConstraintDomains
using Constraints
using CompositionalNetworks

const targets = Dict(
    :all_different => Dict(
        :domains => [domain([1,2,3,4]) for i in 1:4],
    ),
    :dist_different => Dict(
        :domains => [domain(Vector(1:4)) for i in 1:4],
    ),
    :ordered => Dict(
        :domains => [domain([1,2,3,4]) for i in 1:4],
    ),
    :all_equal => Dict(
        :domains => [domain([1,2,3,4]) for i in 1:4],
    ),
    :eq => Dict(
        :domains => [domain(Vector(1:10)) for i in 1:2],
    ),
)

const targets_param = Dict(
    # :all_equal_param => Dict(
    #     :domains => [domain(Vector(8:12)) for i in 1:4],
    #     :param => 10,
    # ),
)

const config = Dict(
    :local_iter => 100,
    :global_iter => 10,
    :search => :complete,
    :metric => hamming,
    :population => 400,
)

for t in targets
    @info "Starting learning for $(t.first)"
    err = explore_learn_compose(
        concept(usual_constraints[t.first]);
        domains = t.second[:domains],
        param = get(t.second, :param, nothing),
        local_iter = config[:local_iter],
        global_iter = config[:global_iter],
        search = config[:search],
        metric = config[:metric],
        popSize = config[:population],    
    )
    name = "_icn_$(t.first)"
    compose_to_file!(
        concept(usual_constraints[t.first]),
        name,
        joinpath(pwd(), "compositions", "$name.jl");
        domains = t.second[:domains],
        param = get(t.second, :param, nothing),
        local_iter = config[:local_iter],
        global_iter = config[:global_iter],
        search = config[:search],
        metric = config[:metric],
        popSize = config[:population],
        language=:Julia,
    )
end

for t in targets_param
    @info "Starting learning for $(t.first)"
    err = explore_learn_compose(
        x -> concept(usual_constraints[t.first])(x, param = get(t.second, :param, nothing));
        domains = t.second[:domains],
        param = get(t.second, :param, nothing),
        local_iter = config[:local_iter],
        global_iter = config[:global_iter],
        search = config[:search],
        metric = config[:metric],
        popSize = config[:population],    
    )
end
