function _icn_all_equal(x; param=nothing, dom_size)
    fill(x, 1) .|> map(f -> (y -> f(y; param=param)), [CompositionalNetworks._tr_identity]) |> CompositionalNetworks._ar_prod |> CompositionalNetworks._ag_count_positive |> (y -> CompositionalNetworks._co_euclidian(y; param=param, dom_size=dom_size, nvars=length(x)))
end
