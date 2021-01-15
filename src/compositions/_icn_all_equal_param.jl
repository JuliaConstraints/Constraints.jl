function _icn_all_equal_param(x; param=nothing, dom_size)
    fill(x, 5) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks._tr_val_minus_param, CompositionalNetworks._tr_count_g_param, CompositionalNetworks._tr_count_l_right, CompositionalNetworks._tr_count_lesser, CompositionalNetworks._tr_count_eq]) |> CompositionalNetworks._ar_sum |> CompositionalNetworks._ag_count_positive |> (y -> CompositionalNetworks._co_identity(y; param=param, dom_size=dom_size, nvars=length(x)))
end
