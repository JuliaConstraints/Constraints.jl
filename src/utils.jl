function insert_or_inc(d::Dictionary{Int,Int}, ind::Int)
    set!(d, ind, isassigned(d, ind) ? d[ind] + 1 : 1)
end
