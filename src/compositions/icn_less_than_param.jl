function icn_less_than_param(x; X = zeros(length(x), 1), param=nothing, dom_size)
    x |> (y -> [CompositionalNetworks.tr_val_minus_param][1](y; param)) |> CompositionalNetworks.ag_count_positive |> (y -> CompositionalNetworks.co_identity(y; param, dom_size, nvars=length(x)))
end
