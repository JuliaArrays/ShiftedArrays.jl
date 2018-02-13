"""
    circshift(v::AbstractArray, n = 1; kwargs...)

Return a `ShiftedArray` object, with underlying data `v`, circularly shifted by `n` steps.
`n` can be an integer, in wich case use the keyword `dims` (defaulting to `1`) to specify on which
dimension to shit.
`n` can also be a `Tuple` denoting the shift in each dimension.

# Examples

```jldoctest circshift
julia> w = reshape(1:16, 4, 4);

julia> ShiftedArrays.circshift(w, (1, -1))
4×4 ShiftedArrays.CircShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 8  12  16  4
 5   9  13  1
 6  10  14  2
 7  11  15  3

 julia> ShiftedArrays.circshift(w, -1, dims = 2)
 4×4 ShiftedArrays.CircShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
  5   9  13  1
  6  10  14  2
  7  11  15  3
  8  12  16  4
```
"""
circshift(v::AbstractArray, n = 1; kwargs...) = CircShiftedArray(v, n; kwargs...)
