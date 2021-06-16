function icn_eq(x; param=nothing, dom_size)
    fill(x, 1) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks.tr_count_lesser]) |> CompositionalNetworks.ar_sum |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_identity(y; param=param, dom_size=dom_size, nvars=length(x)))
end
