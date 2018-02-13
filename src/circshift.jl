"""
    circshift(v::AbstractArray, n::Int = 1; dims = 1)

Return a `ShiftedArray` object, with underlying data `v`, circularly shifted by `n` steps
along dimension `dims`

# Examples

```jldoctest circshift
julia> v = [1, 3, 5, 4];

julia> ShiftedArrays.circshift(v)
4-element ShiftedArrays.CircShiftedArray{Int64,1,Array{Int64,1}}:
 4
 1
 3
 5

julia> w = reshape(1:16, 4, 4);

julia> ShiftedArrays.circshift(w, -1, dims = 2)
4×4 ShiftedArrays.CircShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 5   9  13  1
 6  10  14  2
 7  11  15  3
 8  12  16  4
```
"""
circshift(v::AbstractArray, n::Int = 1; dims = 1) = CircShiftedArray(v, n; dims = dims)

"""
    circshift(v::AbstractArray{T, N}, n::NTuple{N, Int}) where {T, N}

Return a `ShiftedArray` object, with underlying data `v`, circularly shifted by `n` steps,
where `n` is a `Tuple` denoting the shift in each dimension.

# Examples

```jldoctest circshift
julia> w = reshape(1:16, 4, 4);

julia> ShiftedArrays.circshift(w, (1, -1))
4×4 ShiftedArrays.CircShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 8  12  16  4
 5   9  13  1
 6  10  14  2
 7  11  15  3
```
"""
circshift(v::AbstractArray{T, N}, n::NTuple{N, Int}) where {T, N} = CircShiftedArray(v, n)
