function _icn_dist_different(x; param=nothing, dom_size)
    fill(x, 4) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks._tr_count_l_right, CompositionalNetworks._tr_count_lesser, CompositionalNetworks._tr_count_greater, CompositionalNetworks._tr_count_eq_left]) |> CompositionalNetworks._ar_sum |> CompositionalNetworks._ag_count_positive |> (y -> CompositionalNetworks._co_vars_minus_val(y; param=param, dom_size=dom_size, nvars=length(x)))
end
