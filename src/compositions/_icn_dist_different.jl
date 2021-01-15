function _icn_dist_different(x; param=nothing, dom_size)
    fill(x, 4) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks._tr_count_l_left, CompositionalNetworks._tr_count_lesser, CompositionalNetworks._tr_count_greater, CompositionalNetworks._tr_count_eq_right]) |> CompositionalNetworks._ar_sum |> CompositionalNetworks._ag_count_positive |> (y -> CompositionalNetworks._co_abs_diff_val_vars(y; param=param, dom_size=dom_size, nvars=length(x)))
end
