_icn_all_equal = x -> fill(x, 1) .|> [CompositionalNetworks._tr_identity] |> CompositionalNetworks._ar_sum |> CompositionalNetworks._ag_count_positive |> CompositionalNetworks._co_euclidian
