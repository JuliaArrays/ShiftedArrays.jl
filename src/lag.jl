"""
    lag(v::AbstractArray, n = 1; default = missing)

Return a `ShiftedArray` object, with underlying data `v`. The second argument gives the amount
to shift in each dimension. If it is an integer, it is assumed to refer to the first dimension.
`default` specifies a default value when you are out of bounds.

# Examples

```jldoctest lag
julia> v = [1, 3, 5, 4];

julia> lag(v)
4-element ShiftedArray{Int64,Missing,1,Array{Int64,1}}:
  missing
 1
 3
 5

julia> w = 1:2:9
1:2:9

julia> s = lag(w, 2)
5-element ShiftedArray{Int64,Missing,1,StepRange{Int64,Int64}}:
  missing
  missing
 1
 3
 5

julia> copy(s)
5-element Array{Union{Missing, Int64},1}:
  missing
  missing
 1
 3
 5

julia> v = reshape(1:16, 4, 4);

julia> s = lag(v, (0, 2))
4×4 ShiftedArray{Int64,Missing,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 missing  missing  1  5
 missing  missing  2  6
 missing  missing  3  7
 missing  missing  4  8
```
"""
lag(v::AbstractArray, n = 1; default = missing) = ShiftedArray(v, n; default = default)

"""
    lead(v::AbstractArray, n = 1; default = missing)

Return a `ShiftedArray` object, with underlying data `v`. The second argument gives the amount
to shift negatively in each dimension. If it is an integer, it is assumed to refer
to the first dimension. `default` specifies a default value when you are out of bounds.

# Examples

```jldoctest lead
julia> v = [1, 3, 5, 4];

julia> lead(v)
4-element ShiftedArray{Int64,Missing,1,Array{Int64,1}}:
 3
 5
 4
  missing

julia> w = 1:2:9
1:2:9

julia> s = lead(w, 2)
5-element ShiftedArray{Int64,Missing,1,StepRange{Int64,Int64}}:
 5
 7
 9
  missing
  missing

julia> copy(s)
5-element Array{Union{Missing, Int64},1}:
 5
 7
 9
  missing
  missing

julia> v = reshape(1:16, 4, 4);

julia> s = lead(v, (0, 2))
4×4 ShiftedArray{Int64,Missing,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
  9  13  missing  missing
 10  14  missing  missing
 11  15  missing  missing
 12  16  missing  missing
```
"""
lead(v::AbstractArray, n = 1; default = missing) = ShiftedArray(v, map(-, n); default = default)








"""
    lag(v::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing) -> Vector

Shifts with respect to a times given in the vector `times`.  The third variable `period` gives the period by which to shift.
`default` specifies a default value when the shifted time is not in `times`.
Elements in `times` must all be distinct.

# Examples

```jldoctest lead
julia> v = [1, 3, 5, 4];
julia> times = [1990, 1992, 1993];
julia> lag(v, times)
3-element Array{Union{Missing, Int64},1}:
  missing
  missing
 3
julia> using Dates
julia> times = [Date(1990, 1, 1), Date(1990, 1, 3), Date(1990, 1, 4)]
julia> lag(v, times, Day(1))
3-element Array{Union{Missing, Int64},1}:
 missing
 missing
3
"""
function lag(v::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing)
   	# Code follows the function indexin
    inds = keys(times)
    timesdict = Dict{eltype(times),eltype(inds)}()
    for (val, ind) in zip(times, inds)
         out = get!(timesdict, val, ind)
         out != ind && error("Times must be distinct")
    end
    return Union{eltype(v), typeof(default)}[
         (i = get(timesdict, x - period, nothing); i !== nothing ? v[i] : default) for x in times
    ]
end

"""
    lead(v::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing) -> Vector

Shifts with respect to a vector of times `times`. The third variable `period` gives the period by which to shift.
`default` specifies a default value when the shifted time is not in `times`.
Elements in `times` must all be distinct.

# Examples

```jldoctest lead
julia> v = [1, 3, 5, 4];
julia> times = [1990, 1992, 1993];
julia> lead(v, times, 1)
3-element Array{Union{Missing, Int64},1}:
  missing
  5
  missing
"""
function lead(v::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing)
    lag(v, times, -period; default = default)
end
