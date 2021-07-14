function icn_all_different(x; X = zeros(length(x), 1), param=nothing, dom_size)
    x |> (y -> [CompositionalNetworks.tr_count_eq_right][1](y; param)) |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_identity(y; param, dom_size, nvars=length(x)))
end
