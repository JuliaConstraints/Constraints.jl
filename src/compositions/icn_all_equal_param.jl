function icn_all_equal_param(x; X = zeros(length(x), 2), param=nothing, dom_size)
    fill!(@view(X[1:length(x), :]), 0.0)
    CompositionalNetworks.tr_in(Tuple([CompositionalNetworks.tr_param_minus_val, CompositionalNetworks.tr_val_minus_param]), X, x, param)
    for i in 1:length(x)
        X[i,1] = CompositionalNetworks.ar_sum(@view X[i,:])
    end
    return CompositionalNetworks.ag_count_positive(@view X[:, 1]) |> (y -> CompositionalNetworks.co_identity(y; param, dom_size, nvars=length(x)))
end
