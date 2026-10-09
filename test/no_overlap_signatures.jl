@testitem "No-overlap tuple dispatch preserves empty boxes and fallbacks" default_imports=false begin
    import Constraints as C
    using Test, Random

    function former(origins, lengths, zero_ignored)
        length(origins) == length(lengths) || throw(DimensionMismatch(
            "origins and lengths must contain the same number of tasks"))
        previous = (-Inf, -1)
        for t in sort(collect(zip(origins, lengths)))
            zero_ignored && iszero(t[2]) && continue
            sum(previous) <= t[1] || return false
            previous = t
        end
        true
    end
    function former(origins::AbstractVector{NTuple{K,T}},
            lengths::AbstractVector{NTuple{K,T}}, zero_ignored) where {K,T<:Number}
        length(origins) == length(lengths) || throw(DimensionMismatch(
            "origins and lengths must contain the same number of boxes"))
        for i in firstindex(origins):(lastindex(origins)-1)
            first_length = lengths[i]
            for j in (i+1):lastindex(origins)
                second_length = lengths[j]
                zero_ignored &&
                    (any(iszero, first_length) || any(iszero, second_length)) && continue
                first_origin = origins[i]
                second_origin = origins[j]
                separated = any(1:K) do dimension
                    first_origin[dimension] + first_length[dimension] <= second_origin[dimension] ||
                        second_origin[dimension] + second_length[dimension] <= first_origin[dimension]
                end
                separated || return false
            end
        end
        true
    end
    function outcome(f, origins, lengths, zero)
        try
            (:result, f(origins, lengths, zero))
        catch error
            (:error, typeof(error), sprint(showerror, error))
        end
    end

    Random.seed!(81931)
    for T in (Bool, Int8, Int16, Int32, Int64, Int128, UInt8, UInt16,
            UInt32, UInt64, UInt128, Float16, Float32, Float64), dimension in 0:4,
            n in 0:6, zero in (false, true)
        origins = NTuple{dimension,T}[
            ntuple(_ -> T(rand(0:(T===Bool ? 1 : 3))), dimension) for _ in 1:n]
        lengths = NTuple{dimension,T}[
            ntuple(_ -> T(rand(0:(T===Bool ? 1 : 2))), dimension) for _ in 1:n]
        saved_origins, saved_lengths = copy(origins), copy(lengths)
        @test outcome(former, origins, lengths, zero) ==
              outcome(C.xcsp_no_overlap, origins, lengths, zero)
        @test origins == saved_origins && lengths == saved_lengths
        truncated = lengths[1:max(0,n-1)]
        @test outcome(former, origins, truncated, zero) ==
              outcome(C.xcsp_no_overlap, origins, truncated, zero)
        method = which(C.xcsp_no_overlap,
            Tuple{typeof(origins),typeof(lengths),Bool})
        @test !Test.has_unbound_vars(method.sig)
    end

    for zero in (true, false)
        @test C.xcsp_no_overlap(Tuple{}[], Tuple{}[], zero)
        @test C.xcsp_no_overlap(Tuple{}[()], Tuple{}[()], zero)
        @test !C.xcsp_no_overlap(Tuple{}[(),()], Tuple{}[(),()], zero)
        @test_throws DimensionMismatch C.xcsp_no_overlap(Tuple{}[()], Tuple{}[], zero)
    end
    # Different tuple sizes/types and heterogeneous tuples must retain the old
    # scalar fallback, including its errors, rather than gain new dispatch.
    for origins in ([(1,2)], [(1,2.0)], [(1,2,3)], Tuple{}[(),()], [1,2]),
            lengths in ([(1,2)], [(1.0,2.0)], [(1,2,3)], Tuple{}[(),()], [1,2]),
            zero in (false, true, "wrong")
        @test outcome(former, origins, lengths, zero) ==
              outcome(C.xcsp_no_overlap, origins, lengths, zero)
    end
    for T in (Int8, Int64, Int128, UInt8, UInt64, UInt128, Float16, Float32, Float64)
        points = T <: Integer ? T[typemin(T), typemax(T), 0, 1] :
                 T[-Inf, Inf, NaN, -0.0, 0.0, 1.0]
        for dimension in 1:3, a in points, b in points, zero in (false,true)
            origins = [ntuple(_ -> a, dimension), ntuple(_ -> b, dimension)]
            lengths = [ntuple(_ -> b, dimension), ntuple(_ -> a, dimension)]
            @test outcome(former, origins, lengths, zero) ==
                  outcome(C.xcsp_no_overlap, origins, lengths, zero)
        end
    end

    struct ObservedBoxes{T} <: AbstractVector{T}
        values::Vector{T}
        events::Vector{Any}
        label::Symbol
        effect::Symbol
    end
    Base.size(x::ObservedBoxes) =
        (push!(x.events, (:size,x.label)); size(x.values))
    function Base.getindex(x::ObservedBoxes, i::Int)
        push!(x.events, (:read,x.label,i))
        if x.effect===:error && x.label===:origins && i==2
            throw(ArgumentError("observed box failure"))
        elseif x.effect===:mutate && x.label===:lengths && i==1 && length(x.values)>1
            x.values[2] = map(zero, x.values[2])
        end
        x.values[i]
    end
    function observed(dimension, effect)
        events = Any[]
        origins = [ntuple(_ -> i, dimension) for i in 0:2]
        lengths = [ntuple(_ -> 1, dimension) for _ in 0:2]
        (ObservedBoxes(origins,events,:origins,effect),
         ObservedBoxes(lengths,events,:lengths,effect),events)
    end
    for dimension in 0:3, effect in (:none,:mutate,:error), zero in (false,true)
        a, a_lengths, a_events = observed(dimension,effect)
        b, b_lengths, b_events = observed(dimension,effect)
        @test outcome(former,a,a_lengths,zero) == outcome(C.xcsp_no_overlap,b,b_lengths,zero)
        @test a_events == b_events
        @test a.values == b.values && a_lengths.values == b_lengths.values
    end
end
