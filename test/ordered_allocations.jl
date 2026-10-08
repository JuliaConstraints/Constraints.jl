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
