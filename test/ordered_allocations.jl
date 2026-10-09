@testitem "Ordered validators reuse their input storage" begin
    import Constraints: xcsp_ordered

    reference(x, op, offsets) = all(1:(length(x) - 1)) do i
        op(isnothing(offsets) ? x[i] : x[i] + offsets[i], x[i + 1])
    end
    for n in 0:5, assignment in Iterators.product(ntuple(_ -> -1:1, n)...)
        values = collect(assignment)
        for op in ((<), (<=), (>), (>=), (==), (!=)),
                offsets in (nothing, zeros(Int, n), collect(0:(n - 1)))
            @test xcsp_ordered(values, op, offsets) == reference(values, op, offsets)
            @test xcsp_ordered(view(values, :), op, offsets) ==
                  reference(values, op, offsets)
        end
    end

    function allocations(values, offsets)
        xcsp_ordered(values, <=, offsets)
        return @allocated xcsp_ordered(values, <=, offsets)
    end
    values = collect(1:1000)
    @test allocations(values, nothing) == 0
    @test allocations(values, zeros(Int, length(values))) == 0
    @test allocations(view(values, :), nothing) == 0
    @test allocations(view(values, :), view(zeros(Int, length(values)), :)) == 0
    @test allocations(view(reshape(values, 1000, 1), :, 1), nothing) == 0
    @test allocations(view(values, collect(eachindex(values))), nothing) == 0
    @test allocations(1:1000, nothing) == 0
    @test allocations(1:2:1999, nothing) == 0
    @test xcsp_ordered(1:1000, <=, nothing)
    @test_throws BoundsError xcsp_ordered([1, 2, 3], <=, [0])
    for offsets in (nothing, zeros(Int, 3))
        custom_values = [1, 2, 3]
        # A custom comparator observes the original copied right-hand tail.
        comparator = (left, right) -> (custom_values[3] = -99; left <= right)
        @test xcsp_ordered(custom_values, comparator, offsets)
        @test custom_values == [1, 2, -99]
    end
end

@testitem "Ordered custom storage preserves snapshot and read order" begin
    import Constraints: xcsp_ordered

    struct ObservedOrderedVector{F} <: AbstractVector{Int}
        values::Vector{Int}
        events::Vector{Tuple{Symbol,Int}}
        onread::F
    end
    Base.IndexStyle(::Type{<:ObservedOrderedVector}) = IndexLinear()
    Base.size(values::ObservedOrderedVector) = size(values.values)
    function Base.axes(values::ObservedOrderedVector)
        push!(values.events, (:axes, 0))
        return axes(values.values)
    end
    function Base.getindex(values::ObservedOrderedVector, index::Int)
        push!(values.events, (:read, index))
        values.onread(index)
        return values.values[index]
    end

    reference(values, op, ::Nothing) =
        invoke(xcsp_ordered, Tuple{Any,Any,Nothing}, values, op, nothing)
    reference(values, op, offsets) =
        invoke(xcsp_ordered, Tuple{Any,Any,Any}, values, op, offsets)
    function capture(f)
        try
            return (:result, f())
        catch error
            return (:error, typeof(error))
        end
    end

    function fixture(kind, with_offsets)
        backing = [1, 2, 3]
        events = Tuple{Symbol,Int}[]
        mutate = index -> (index == 1 && (backing[end] = 0); nothing)
        values = if kind == :list
            ObservedOrderedVector(backing, events, mutate)
        elseif kind == :parent
            view(ObservedOrderedVector(backing, events, mutate), :)
        elseif kind == :selector
            selectors = ObservedOrderedVector([1, 2, 3], events, mutate)
            view(backing, selectors)
        else
            backing
        end
        offsets = if kind == :offsets
            ObservedOrderedVector(zeros(Int, 3), events, mutate)
        elseif kind == :short_offsets
            ObservedOrderedVector([0], events, mutate)
        elseif with_offsets
            zeros(Int, 3)
        else
            nothing
        end
        # Constructing a view may query its parent or selectors.
        backing .= (1, 2, 3)
        empty!(events)
        return (; values, offsets, backing, events)
    end

    for kind in (:list, :parent, :selector, :offsets, :short_offsets),
            with_offsets in (false, true),
            op in ((<), (<=), (>), (>=), (==), (!=))
        actual = fixture(kind, with_offsets)
        expected = fixture(kind, with_offsets)
        @test capture(() -> xcsp_ordered(actual.values, op, actual.offsets)) ==
              capture(() -> reference(expected.values, op, expected.offsets))
        @test actual.events == expected.events
        @test actual.backing == expected.backing
    end
    for kind in (:list, :parent, :selector, :offsets)
        actual = fixture(kind, true)
        @test xcsp_ordered(actual.values, <=, actual.offsets)
        @test actual.backing == [1, 2, 0]
    end

    # Floating ranges keep the original slice reconstruction and rounding.
    for values in (range(0.1; step=0.1, length=10), range(-1.0, 1.0; length=17)),
            op in ((<), (<=), (>), (>=), (==), (!=)),
            offsets in (nothing, zeros(length(values)))
        @test xcsp_ordered(values, op, offsets) == reference(values, op, offsets)
    end
end
