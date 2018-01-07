"""
    lag(v::AbstractVector, n = 1)

Return a `ShiftedVector` object, with underlying data `v`, shifted by `-n` steps.

# Examples

```jldoctest lag
julia> v = [1, 3, 5, 4];

julia> lag(v)
4-element WindowFunctions.ShiftedVector{Int64,Array{Int64,1}}:
  missing
 1       
 3       
 5       

julia> w = 1:2:9
1:2:9

julia> s = lag(w, 2)
5-element WindowFunctions.ShiftedVector{Int64,StepRange{Int64,Int64}}:
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
lag(v::AbstractVector, n = 1) = ShiftedVector(v, -n)

"""
    lead(v::AbstractVector, n = 1)

Return a `ShiftedVector` object, with underlying data `v`, shifted by `n` steps.

# Examples

```jldoctest lead
julia> v = [1, 3, 5, 4];

julia> lead(v)
4-element WindowFunctions.ShiftedVector{Int64,Array{Int64,1}}:
 3       
 5       
 4       
  missing

julia> w = 1:2:9
1:2:9

julia> s = lead(w, 2)
5-element WindowFunctions.ShiftedVector{Int64,StepRange{Int64,Int64}}:
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
lead(v::AbstractVector, n = 1) = ShiftedVector(v, n)