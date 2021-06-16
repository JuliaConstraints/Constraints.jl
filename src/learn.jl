function learn_from_icn()
    targets = Dict(
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
        :less_than_param => Dict(
            :domains => [domain(0:4) for i in 1:1],
            :param => 2,
        ),
        :minus_equal_param => Dict(
            :domains => [domain(0:4) for i in 1:2],
            :param => 3,
        ),
        :ordered => Dict(
            :domains => [domain(1:4) for i in 1:4],
        ),
        :sequential_tasks => Dict(
            :domains => [domain(1:4) for i in 1:4],
        ),
        :sum_equal_param => Dict(
            :domains => [domain(1:9) for i in 1:3],
            :param => 15,
        ),
    )

    config = Dict(
        :local_iter => 100,
        :global_iter => 100,
        :search => :complete,
        :metric => hamming,
        :population => 400,
    )

    path = joinpath(dirname(pathof(Constraints)),"compositions")

    for t in targets
        @info "Starting learning for $(t.first)"
        name = "icn_$(t.first)"
        compose_to_file!(
            concept(usual_constraints[t.first]),
            name,
            joinpath(path, "$name.jl");
            domains=t.second[:domains],
            param=get(t.second, :param, nothing),
            local_iter=config[:local_iter],
            global_iter=config[:global_iter],
            search=config[:search],
            metric=config[:metric],
            popSize=config[:population],
            language=:Julia,
        )
    end

end
