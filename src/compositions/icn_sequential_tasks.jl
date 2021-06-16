function icn_sequential_tasks(x; param=nothing, dom_size)
    fill(x, 3) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks.tr_contiguous_vals_minus_rev, CompositionalNetworks.tr_count_g_left, CompositionalNetworks.tr_count_eq_right]) |> CompositionalNetworks.ar_prod |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_identity(y; param=param, dom_size=dom_size, nvars=length(x)))
end
