function _concept_dist_different(i::T, j::T, k::T, l::T) where {T <: Number}
    return abs(i - j) ≠ abs(k - l)
end

"""
    dist_different
Local constraint ensuring that `concept(dist_different, i, j, k, l) = |i - j| ≠ |k - l|)`.
"""
const _dist_different = Constraint(
    args_length = 4,
    concept = _concept_dist_different,
)