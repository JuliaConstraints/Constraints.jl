function _icn_eq(x; param=nothing, dom_size)
    fill(x, 1) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks._tr_count_lesser]) |> CompositionalNetworks._ar_sum |> CompositionalNetworks._ag_sum |> (y -> CompositionalNetworks._co_identity(y; param=param, dom_size=dom_size, nvars=length(x)))
end
