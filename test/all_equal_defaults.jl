@testitem "AllEqual default offsets preserve observations" default_imports=false begin
    import Constraints as C
    import ConstraintCommons as CC
    using Test

    original_value(x, val) = all(y -> y == val, x)
    original_value(x, ::Nothing) = original(x; val=first(x))
    function original(x; val=nothing, pair_vars=zeros(eltype(x), length(x)), op=+)
        if iszero(pair_vars)
            return original_value(x, val)
        end
        aux = map(t -> op(t...), Iterators.zip(x, pair_vars))
        return original_value(aux, val)
    end
    function capture(f)
        try
            (:result, f())
        catch error
            fields = NamedTuple{fieldnames(typeof(error))}(
                ntuple(i -> getfield(error, i), fieldcount(typeof(error))))
            (:error, typeof(error), fields)
        end
    end
    for T in (Bool, Int8, Int16, Int32, Int64, Int128,
              UInt8, UInt16, UInt32, UInt64, UInt128, Float16, Float32, Float64)
        vals = T === Bool ? T[false,true] : T <: AbstractFloat ?
            T[-Inf,-1,-0.0,0.0,1,Inf,NaN] :
            T[typemin(T),zero(T),one(T),typemax(T)]
        vectors = [T[], T[zero(T)], T[zero(T),zero(T)], T[zero(T),one(T)]]
        append!(vectors, [T[a,b,c] for a in vals for b in vals for c in vals])
        for x in vectors, params in ((;), (;val=zero(T)), (;pair_vars=nothing),
                (;pair_vars=zeros(T,length(x))),
                (;pair_vars=ones(Int,length(x)),val=1,op=+),
                (;pair_vars=Int[],val=0,op=*))
            before = copy(reinterpret(UInt8,x))
            @test isequal(capture(() -> C.concept_all_equal(x;params...)),
                          capture(() -> original(x;params...)))
            @test reinterpret(UInt8,x) == before
        end
    end
    for x in (BigInt[1,1,2], Rational{Int}[1,1,2], Real[1,1.0,2],
              view([1,1,2], :), reshape([1,1,2], 3))
        for params in ((;), (;val=1), (;pair_vars=nothing),
                       (;pair_vars=zeros(Int,length(x))))
            @test isequal(capture(() -> C.concept_all_equal(x;params...)),
                          capture(() -> original(x;params...)))
        end
    end

    struct ObservedEqualVector <: AbstractVector{Int}
        values::Vector{Int}
        events::Vector{Tuple{Symbol,Int}}
        throw_at::Int
        mutate::Bool
    end
    Base.IndexStyle(::Type{ObservedEqualVector}) = IndexLinear()
    Base.size(x::ObservedEqualVector) = size(x.values)
    function Base.eltype(x::ObservedEqualVector)
        push!(x.events,(:eltype,0)); Int
    end
    function Base.length(x::ObservedEqualVector)
        push!(x.events,(:length,0)); length(x.values)
    end
    function Base.getindex(x::ObservedEqualVector,index::Int)
        push!(x.events,(:read,index))
        index == x.throw_at && error("late equality read")
        x.mutate && index == 1 && (x.values[end] = 7)
        x.values[index]
    end
    function simple_capture(f)
        try (:result,f()) catch error
            if error isa BoundsError
                return (:error,typeof(error),typeof(error.a),error.i)
            elseif error isa MethodError
                return (:error,typeof(error),error.f,error.args)
            end
            (:error,typeof(error),error isa ErrorException ? error.msg : nothing)
        end
    end
    for count in (0,1,2,3,5), throw_at in (0,1,3), mutate in (false,true),
            mode in (:default,:scalar,:zero,:offset,:nothing)
        a=ObservedEqualVector(ones(Int,count),Tuple{Symbol,Int}[],throw_at,mutate)
        b=ObservedEqualVector(ones(Int,count),Tuple{Symbol,Int}[],throw_at,mutate)
        params = mode===:scalar ? (;val=1) :
                 mode===:zero ? (;pair_vars=zeros(Int,count)) :
                 mode===:offset ? (;pair_vars=ones(Int,count),val=2) :
                 mode===:nothing ? (;pair_vars=nothing) : (;)
        actual=simple_capture(() -> C.concept_all_equal(a;params...))
        expected=simple_capture(() -> original(b;params...))
        @test isequal(actual,expected)
        @test a.events == b.events
        @test a.values == b.values
    end

    const ZERO_EVENTS = Ref(Tuple{Symbol,Int,Int}[])
    const THROW_ZERO = Ref(false)
    struct ObservedEqualNumber <: Real
        value::Int
    end
    function Base.zero(::Type{ObservedEqualNumber})
        push!(ZERO_EVENTS[],(:zero,0,0))
        THROW_ZERO[] && error("custom default zero")
        ObservedEqualNumber(0)
    end
    function Base.iszero(x::ObservedEqualNumber)
        push!(ZERO_EVENTS[],(:iszero,x.value,0))
        iszero(x.value)
    end
    function Base.:(==)(a::ObservedEqualNumber,b::ObservedEqualNumber)
        push!(ZERO_EVENTS[],(:equal,a.value,b.value))
        a.value==b.value
    end
    for count in (0,1,2,5), throws in (false,true)
        x=fill(ObservedEqualNumber(1),count)
        ZERO_EVENTS[]=Tuple{Symbol,Int,Int}[];THROW_ZERO[]=throws
        actual=simple_capture(() -> C.concept_all_equal(x))
        events=copy(ZERO_EVENTS[])
        ZERO_EVENTS[]=Tuple{Symbol,Int,Int}[]
        expected=simple_capture(() -> original(x))
        @test isequal(actual,expected)
        @test events==ZERO_EVENTS[]
    end
    THROW_ZERO[]=false

    for x in (Int[],[1],[1,1],[1,2],[1,1,2]),
            offsets in (nothing,Int[],zeros(Int,length(x)),ones(Int,length(x))),
            throws in (false,true)
        events_a=Tuple{Int,Int}[];events_b=Tuple{Int,Int}[]
        op_a=(a,b)->begin
            push!(events_a,(a,b));throws && a==2 && error("offset arithmetic");a+b
        end
        op_b=(a,b)->begin
            push!(events_b,(a,b));throws && a==2 && error("offset arithmetic");a+b
        end
        actual=simple_capture(() -> C.concept_all_equal(x;pair_vars=offsets,op=op_a))
        expected=simple_capture(() -> original(x;pair_vars=offsets,op=op_b))
        @test isequal(actual,expected)
        @test events_a==events_b
    end

    registered=C.USUAL_CONSTRAINTS[:all_equal]
    @test registered.params == [Dict(:val=>true,:pair_vars=>true,:op=>true)]
    @test C.constraint_spec(:all_equal).schemas == registered.params
    declarations=CC.extract_parameters(C.concept_all_equal)
    @test count(==([:val,:pair_vars,:op]),declarations)==1
    for x in ([1],[1,1],[1,2])
        @test C.concept(:all_equal)(x) == original(x)
        @test C.error_f(registered)(x) == Float64(!original(x))
    end
end
