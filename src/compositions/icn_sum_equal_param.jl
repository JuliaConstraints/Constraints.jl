function icn_sum_equal_param(x; param=nothing, dom_size)
    fill(x, 2) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks.tr_count_greater, CompositionalNetworks.tr_count_eq_left]) |> CompositionalNetworks.ar_sum |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_vars_minus_val(y; param=param, dom_size=dom_size, nvars=length(x)))
end
