"""
    lag(v::AbstractArray, n = 1)

Return a `ShiftedArray` object, with underlying data `v`. The second argument gives the amount
to shift in each dimension. If it is an integer, it is assumed to refer to the first dimension.

# Examples

```jldoctest lag
julia> v = [1, 3, 5, 4];

julia> lag(v)
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
  missing
 1
 3
 5

julia> w = 1:2:9
1:2:9

julia> s = lag(w, 2)
5-element ShiftedArrays.ShiftedArray{Int64,1,StepRange{Int64,Int64}}:
  missing
  missing
 1
 3
 5

julia> copy(s)
5-element Array{Union{Int64, Missings.Missing},1}:
  missing
  missing
 1
 3
 5

julia> v = reshape(1:16, 4, 4);

julia> s = lag(v, (0, 2))
4×4 ShiftedArrays.ShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 missing  missing  1  5
 missing  missing  2  6
 missing  missing  3  7
 missing  missing  4  8
```
"""
lag(v::AbstractArray, n = 1) = ShiftedArray(v, n)

"""
    lead(v::AbstractArray, n = 1; dim = 1)

Return a `ShiftedArray` object, with underlying data `v`. The second argument gives the amount
to shift negatively in each dimension. If it is an integer, it is assumed to refer
to the first dimension.


# Examples

```jldoctest lead
julia> v = [1, 3, 5, 4];

julia> lead(v)
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
 3
 5
 4
  missing

julia> w = 1:2:9
1:2:9

julia> s = lead(w, 2)
5-element ShiftedArrays.ShiftedArray{Int64,1,StepRange{Int64,Int64}}:
 5
 7
 9
  missing
  missing

julia> copy(s)
5-element Array{Union{Int64, Missings.Missing},1}:
 5
 7
 9
  missing
  missing

julia> v = reshape(1:16, 4, 4);

julia> s = lag(v, (0, 2))
4×4 ShiftedArrays.ShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 missing  missing  1  5
 missing  missing  2  6
 missing  missing  3  7
 missing  missing  4  8
```
"""
lead(v::AbstractArray, n = 1) = ShiftedArray(v, map(-, n))
