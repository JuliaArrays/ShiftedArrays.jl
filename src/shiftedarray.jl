"""
    padded_tuple(v::AbstractVector, s)

Internal function used to compute shifts. Return a `Tuple` with as many element
as the dimensions of `v`. The first `length(s)` entries are filled with values
from `s`, the remaining entries are `0`. `s` should be an integer, in which case
`length(s) == 1`, or a container of integers with keys `1:length(s)`.

# Examples

```jldoctest padded_tuple
julia> ShiftedArrays.padded_tuple(rand(10, 10), 3)
(3, 0)

julia> ShiftedArrays.padded_tuple(rand(10, 10), (4,))
(4, 0)

julia> ShiftedArrays.padded_tuple(rand(10, 10), (1, 5))
(1, 5)
```
"""
padded_tuple(v::AbstractArray, s) = ntuple(i -> i ≤ length(s) ? s[i] : 0, ndims(v))

"""
    ShiftedArray(parent::AbstractArray, shifts, default)

Custom `AbstractArray` object to store an `AbstractArray` `parent` shifted by `shifts` steps (where `shifts` is
a `Tuple` with one `shift` value per dimension of `parent`).
For `s::ShiftedArray`, `s[i...] == s.parent[map(-, i, s.shifts)...]` if `map(-, i, s.shifts)`
is a valid index for `s.parent`, and `s.v[i, ...] == default` otherwise.
Use `copy` to collect the values of a `ShiftedArray` into a normal `Array`.
The recommended constructor is `ShiftedArray(parent, shifts; default = missing)`

# Examples

```jldoctest shiftedarray
julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedVector{Int64, Missing, Vector{Int64}}:
  missing
 1
 3
 5

julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedVector{Int64, Missing, Vector{Int64}}:
  missing
 1
 3
 5

julia> copy(s)
4-element Vector{Union{Missing, Int64}}:
  missing
 1
 3
 5

julia> v = reshape(1:16, 4, 4);

julia> s = ShiftedArray(v, (0, 2))
4×4 ShiftedArray{Int64, Missing, 2, Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}}:
 missing  missing  1  5
 missing  missing  2  6
 missing  missing  3  7
 missing  missing  4  8

julia> shifts(s)
(0, 2)
```
"""
struct ShiftedArray{T, M, N, S<:AbstractArray} <: AbstractArray{Union{T, M}, N}
    parent::S
    shifts::NTuple{N, Int}
    default::M
end

ShiftedArray(v::AbstractArray{T, N}, n = (); default::M = missing) where {T, N, M} =
     ShiftedArray{T, M, N, typeof(v)}(v, padded_tuple(v, n), default)

"""
    ShiftedVector{T, S<:AbstractArray}

Shorthand for `ShiftedArray{T, 1, S}`.
"""
const ShiftedVector{T, M, S<:AbstractArray} = ShiftedArray{T, M, 1, S}

ShiftedVector(v::AbstractVector, n = (); default = missing) = ShiftedArray(v, n; default = default)

size(s::ShiftedArray) = size(parent(s))
axes(s::ShiftedArray) = axes(parent(s))

# Computing a shifted index (subtracting the offset)
offset(offsets::NTuple{N,Int}, inds::NTuple{N,Int}) where {N} = map(-, inds, offsets)

@inline function getindex(s::ShiftedArray{<:Any, <:Any, N}, x::Vararg{Int, N}) where {N}
    @boundscheck checkbounds(s, x...)
    v, i = parent(s), offset(shifts(s), x)
    return if checkbounds(Bool, v, i...)
        @inbounds v[i...]
    else
        default(s)
    end
end

parent(s::ShiftedArray) = s.parent

"""
    shifts(s::ShiftedArray)

Return amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(s::ShiftedArray) = s.shifts

"""
    default(s::ShiftedArray)

Return default value.
"""
default(s::ShiftedArray) = s.default
