function icn_all_equal(x; param=nothing, dom_size)
    fill(x, 1) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks.tr_identity]) |> CompositionalNetworks.ar_sum |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_euclidian(y; param=param, dom_size=dom_size, nvars=length(x)))
end
