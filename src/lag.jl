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
Elements in `times` must be all sorted and distinct.

# Examples

```jldoctest lead
julia> v = [1, 3, 5];
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

struct LaggedVector{T <: AbstractVector, U <: AbstractVector, P, M, R} <: AbstractVector{Union{R, M}} 
  parent::T
  times::U
  period::P
  default::M
end

function LaggedVector(parent::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing)
  length(parent) == length(times) || error("Values and times must have the same length")
  is_sorted_and_unique(times)
  LaggedVector{typeof(parent), typeof(times), typeof(period), typeof(default), eltype(parent)}(parent, times, period, default)
end

function is_sorted_and_unique(times::AbstractVector)
  t, rest = Iterators.peel(times)
  for r in rest
    r == t && error("Times must be distinct")
    r < t && error("Times must be sorted")
    t = r
  end
end

parent(s::LaggedVector) = s.parent

Base.size(s::LaggedVector) = size(parent(s))

@inline function getindex(s::LaggedVector{T, U, P, M}, i::Integer) where{T, U, P, M}
  t = s.times[i] - s.period
  incr = (s.times[i] >= t) ? 1 : -1
  while checkbounds(Bool, s.times, i) && ((incr == 1) ? (@inbounds s.times[i] > t) : (@inbounds s.times[i] < t))
    i -= incr
  end
  if checkbounds(Bool, s.times, i) && (@inbounds s.times[i] == t)
    return s.parent[i]::eltype(T)
  else
    return s.default::M
  end
end

function lag(v::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing)
    LaggedVector(v, times, period; default = default)
end
function lead(v::AbstractVector, times::AbstractVector, period = oneunit(eltype(times)); default = missing)
    LaggedVector(v, times, -period; default = default)
end
