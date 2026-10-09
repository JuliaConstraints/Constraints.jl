@testitem "Sum default coefficients preserve observations" default_imports=false begin
    import Constraints as C
    import ConstraintCommons as CC
    using Test, Random

    original(x; op = ==, pair_vars = ones(eltype(x), length(x)), val) =
        op(sum(pair_vars .* x), val)
    total(a, b) = a
    function capture(f)
        try
            value = f()
            if value isa AbstractFloat
                U = typeof(value) === Float16 ? UInt16 :
                    typeof(value) === Float32 ? UInt32 : UInt64
                return (:result, typeof(value), reinterpret(U, value))
            end
            (:result, typeof(value), value)
        catch error
            if error isa BoundsError
                return (:error, typeof(error), typeof(error.a), error.i)
            elseif error isa MethodError
                return (:error, typeof(error), error.f, error.args)
            end
            fields = NamedTuple{fieldnames(typeof(error))}(
                ntuple(i -> getfield(error, i), fieldcount(typeof(error))))
            (:error, typeof(error), fields)
        end
    end

    for T in (Bool, Int8, Int16, Int32, Int64, Int128,
              UInt8, UInt16, UInt32, UInt64, UInt128)
        vals = T === Bool ? T[false, true] :
            T[typemin(T), zero(T), one(T), typemax(T)]
        vectors = [T[], T[zero(T)], T[one(T)], T[zero(T), one(T)]]
        append!(vectors, [T[a, b, c] for a in vals for b in vals for c in vals])
        append!(vectors, [[vals[mod1(i, length(vals))] for i in 1:n]
            for n in (15, 16, 17, 1023, 1024, 1025, 2048)])
        for x in vectors, params in (
                (; op=total, val=nothing), (; val=0), (; op=<=, val=2),
                (; op=total, val=nothing, pair_vars=nothing),
                (; op=total, val=nothing, pair_vars=zeros(T, length(x))),
                (; op=total, val=nothing, pair_vars=ones(T, length(x))),
                (; op=total, val=nothing, pair_vars=Int[]),
                (; op=total, val=nothing, pair_vars=[2]))
            before = copy(reinterpret(UInt8, x))
            @test isequal(capture(() -> C.concept_sum(x; params...)),
                          capture(() -> original(x; params...)))
            @test reinterpret(UInt8, x) == before
        end
        for n in (0, 1, 2, 1000)
            x = fill(typemax(T), n)
            @test @inferred(C.concept_sum(x; op=total, val=nothing)) === sum(x)
        end
    end

    # Keep multiplication and its eager product vector for floating defaults.
    # Multiplication by a compile-time one can change a Float16 NaN payload.
    rng = MersenneTwister(91373)
    for (T, U) in ((Float16, UInt16), (Float32, UInt32), (Float64, UInt64)),
            n in (0, 1, 2, 3, 15, 16, 17, 1023, 1024, 1025, 2048), trial in 1:100
        x = collect(reinterpret(T, rand(rng, U, n)))
        before = copy(reinterpret(UInt8, x))
        @test isequal(capture(() -> C.concept_sum(x; op=total, val=nothing)),
                      capture(() -> original(x; op=total, val=nothing)))
        @test reinterpret(UInt8, x) == before
    end
    for x in (BigInt[1, 1, 2], Rational{Int}[1, 1, 2], Real[1, 1.0, 2],
              view([1, 1, 2], :), reshape([1, 1, 2], 3))
        for params in ((; op=total, val=nothing),
                      (; op=total, val=nothing, pair_vars=ones(Int, length(x))))
            @test isequal(capture(() -> C.concept_sum(x; params...)),
                          capture(() -> original(x; params...)))
        end
    end

    struct ObservedSumVector <: AbstractVector{Int}
        values::Vector{Int}
        events::Vector{Tuple{Symbol, Int}}
        throw_at::Int
        mutate::Bool
    end
    Base.IndexStyle(::Type{ObservedSumVector}) = IndexLinear()
    function Base.size(x::ObservedSumVector)
        push!(x.events, (:size, 0)); size(x.values)
    end
    function Base.eltype(x::ObservedSumVector)
        push!(x.events, (:eltype, 0)); Int
    end
    function Base.length(x::ObservedSumVector)
        push!(x.events, (:length, 0)); length(x.values)
    end
    function Base.getindex(x::ObservedSumVector, index::Int)
        push!(x.events, (:read, index))
        index == x.throw_at && error("late sum read")
        x.mutate && index == 1 && (x.values[end] = 7)
        x.values[index]
    end
    for count in (0, 1, 2, 3, 5), throw_at in (0, 1, 3), mutate in (false, true),
            mode in (:default, :ones, :offset, :empty, :nothing)
        a = ObservedSumVector(ones(Int, count), Tuple{Symbol, Int}[], throw_at, mutate)
        b = ObservedSumVector(ones(Int, count), Tuple{Symbol, Int}[], throw_at, mutate)
        params = mode === :default ? (; op=total, val=nothing) :
            (; op=total, val=nothing, pair_vars=mode === :ones ? ones(Int, count) :
                mode === :offset ? fill(2, count) : mode === :empty ? Int[] : nothing)
        @test isequal(capture(() -> C.concept_sum(a; params...)),
                      capture(() -> original(b; params...)))
        @test a.events == b.events
        @test a.values == b.values
    end

    const SUM_EVENTS = Ref(Tuple{Symbol, Int, Int}[])
    const THROW_ONE = Ref(false)
    const THROW_PRODUCT = Ref(false)
    struct ObservedSumNumber <: Real
        value::Int
    end
    function Base.one(::Type{ObservedSumNumber})
        push!(SUM_EVENTS[], (:one, 0, 0))
        THROW_ONE[] && error("custom default one")
        ObservedSumNumber(1)
    end
    function Base.zero(::Type{ObservedSumNumber})
        push!(SUM_EVENTS[], (:zero, 0, 0)); ObservedSumNumber(0)
    end
    function Base.:(*)(a::ObservedSumNumber, b::ObservedSumNumber)
        push!(SUM_EVENTS[], (:product, a.value, b.value))
        THROW_PRODUCT[] && b.value == 2 && error("custom product")
        ObservedSumNumber(a.value * b.value)
    end
    function Base.:(+)(a::ObservedSumNumber, b::ObservedSumNumber)
        push!(SUM_EVENTS[], (:add, a.value, b.value))
        ObservedSumNumber(a.value + b.value)
    end
    for count in (0, 1, 2, 5), one_throws in (false, true), product_throws in (false, true)
        x = [ObservedSumNumber(i) for i in 1:count]
        THROW_ONE[] = one_throws; THROW_PRODUCT[] = product_throws
        SUM_EVENTS[] = Tuple{Symbol, Int, Int}[]
        actual = capture(() -> C.concept_sum(x; op=total, val=nothing))
        events = copy(SUM_EVENTS[])
        SUM_EVENTS[] = Tuple{Symbol, Int, Int}[]
        expected = capture(() -> original(x; op=total, val=nothing))
        @test isequal(actual, expected)
        @test events == SUM_EVENTS[]
    end
    THROW_ONE[] = false; THROW_PRODUCT[] = false

    for x in (Int[], [1], [1, 2], fill(typemax(Int), 1000))
        events_a = Any[]; events_b = Any[]
        op_a = (a,b) -> (push!(events_a, (typeof(a), a, b)); error("sum operator"))
        op_b = (a,b) -> (push!(events_b, (typeof(a), a, b)); error("sum operator"))
        @test isequal(capture(() -> C.concept_sum(x; op=op_a, val=2)),
                      capture(() -> original(x; op=op_b, val=2)))
        @test events_a == events_b
        @test isequal(capture(() -> C.concept_sum(x)), capture(() -> original(x)))
    end
    registered = C.USUAL_CONSTRAINTS[:sum]
    @test registered.params == [Dict(:op=>true, :pair_vars=>true, :val=>false)]
    @test C.constraint_spec(:sum).schemas == registered.params
    @test count(==([:op, :pair_vars, :val]), CC.extract_parameters(C.concept_sum)) == 1
    for x in (Int[], [1], [1, 2]), val in (0, 1, 3)
        @test C.concept(:sum)(x; val) == original(x; val)
        @test C.error_f(registered)(x; val) == Float64(!original(x; val))
    end
end
