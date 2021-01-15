# Learning through ICNs

This feature is very basic so far, and should follow the procedure below
- Make the package a dev version `] dev Constraints`
- (Recommended) In `user_home/.julia/dev/Constraints`, `git checkout -b newcomposition`
- Define a new constraint `_c` and add it to `usual_constraint` in `Constraints.jl`
- Add it to the list of constraints to be learned in `learn.jl` (check the function below)
- Enter a new julia session, and run
  ```julia
  using Constraints
  Constraints.learn_from_icn()
  ```
- Run tests: `] test Constraints`
- Commit, push, and make a draft PR to the dev branch

```julia
function learn_from_icn()
    targets = Dict(
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
        :all_equal_param => Dict(
            :domains => [domain(Vector(8:12)) for i in 1:4],
            :param => 10,
        ),
    )

    config = Dict(
        :local_iter => 100,
        :global_iter => 10,
        :search => :complete,
        :metric => hamming,
        :population => 400,
    )

    path = joinpath(dirname(pathof(Constraints)),"compositions")

    for t in targets
        @info "Starting learning for $(t.first)"
        name = "_icn_$(t.first)"
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
```