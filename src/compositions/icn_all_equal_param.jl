function icn_all_equal_param(x; param=nothing, dom_size)
    fill(x, 2) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks.tr_param_minus_val, CompositionalNetworks.tr_val_minus_param]) |> CompositionalNetworks.ar_sum |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_identity(y; param=param, dom_size=dom_size, nvars=length(x)))
end
