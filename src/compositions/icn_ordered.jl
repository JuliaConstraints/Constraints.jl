function icn_ordered(x; param=nothing, dom_size)
    fill(x, 1) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks.tr_contiguous_vals_minus]) |> CompositionalNetworks.ar_sum |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_identity(y; param=param, dom_size=dom_size, nvars=length(x)))
end
