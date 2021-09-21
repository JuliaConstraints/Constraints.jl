function insert_or_inc(d::Dictionary{Int,Int}, ind::Int)
    set!(d, ind, isassigned(d, ind) ? d[ind] + 1 : 1)
end

function Base.:*(s1::Symbol, s2::Symbol, connector::AbstractString="_")
    return Symbol(string(s1) * connector * string(s2))
end
