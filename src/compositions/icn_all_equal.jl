function icn_all_equal(x; X = zeros(length(x), 3), param=nothing, dom_size)
    CompositionalNetworks.tr_in(Tuple([CompositionalNetworks.tr_contiguous_vals_minus, CompositionalNetworks.tr_count_l_left, CompositionalNetworks.tr_count_greater]), X, x, param)
    for i in 1:length(x)
        X[i,1] = CompositionalNetworks.ar_sum(@view X[i,:])
    end
    return CompositionalNetworks.ag_count_positive(@view X[:, 1]) |> (y -> CompositionalNetworks.co_euclidian(y; param, dom_size, nvars=length(x)))
end
