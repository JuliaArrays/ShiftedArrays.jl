"""
    lag(v::AbstractArray, n = 1; dims = 1)

Return a `ShiftedArray` object, with underlying data `v`, shifted by `n` steps
along dimension `dims`

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
```
"""
lag(v::AbstractArray, n::Int = 1; dims = 1) = ShiftedArray(v, n; dims = dims)

lag(v::AbstractArray{T, N}, n::NTuple{N, Int}) where {T, N} =
    ShiftedArray(v, n)

lag(v::AbstractArray, n; dims = (1,)) = ShiftedArray(v, n; dims = dims)

"""
    lead(v::AbstractArray, n = 1; dims = 1)

Return a `ShiftedArray` object, with underlying data `v`, shifted by `-n` steps.

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
```
"""
lead(v::AbstractArray, n::Int = 1; dims = 1) = ShiftedArray(v, -n; dims = dims)

lead(v::AbstractArray{T, N}, n::NTuple{N, Int}) where {T, N} =
    ShiftedArray(v, map(-, n))

lead(v::AbstractArray, n; dims = (1,)) = ShiftedArray(v, map(-, n); dims = dims)
