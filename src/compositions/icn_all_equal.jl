function icn_all_equal(x; param=nothing, dom_size)
    fill(x, 2) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks.tr_count_lesser, CompositionalNetworks.tr_count_greater]) |> CompositionalNetworks.ar_sum |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_euclidian(y; param=param, dom_size=dom_size, nvars=length(x)))
end
