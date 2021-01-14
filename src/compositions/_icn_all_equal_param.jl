function _icn_all_equal_param(x; param=nothing, dom_size)
    fill(x, 1) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks._tr_count_g_param]) |> CompositionalNetworks._ar_sum |> CompositionalNetworks._ag_sum |> (y -> CompositionalNetworks._co_vars_minus_val(y; param=param, dom_size=dom_size, nvars=length(x)))
end
