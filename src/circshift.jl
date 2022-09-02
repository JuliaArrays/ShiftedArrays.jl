"""
    circshift(v::AbstractArray, n)

Return a `CircShiftedArray` object which lazily represents the array `v`
shifted circularly by `n`.
The second argument `n` specifies the amount to shift circularly in each dimension.
If it is an integer, it is assumed to refer to the first dimension.

# Examples

```jldoctest circshift
julia> v = [1, 3, 5, 4];

julia> ShiftedArrays.circshift(v, 1)
4-element CircShiftedVector{Int64, Vector{Int64}}:
 4
 1
 3
 5

julia> w = reshape(1:16, 4, 4);

julia> ShiftedArrays.circshift(w, (1, -1))
4×4 CircShiftedArray{Int64, 2, Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}}:
 8  12  16  4
 5   9  13  1
 6  10  14  2
 7  11  15  3
```
"""
circshift(v::AbstractArray, n) = CircShiftedArray(v, n)
