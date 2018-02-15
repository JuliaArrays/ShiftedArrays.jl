_padded_tuple(n, N) = Tuple(i <= length(n) ? n[i] : 0 for i in 1:N)
_padded_tuple(n::Int, N) = _padded_tuple((n,), N)

"""
    ShiftedArray(parent::AbstractArray, shifts)

Custom `AbstractArray` object to store an `AbstractArray` `parent` shifted by `shifts` steps (where `shifts` is
a `Tuple` with one `shift` value per dimension of `parent`).
For `s::ShiftedArray`, `s[i...] == s.parent[map(-, i, s.shifts)...]` if `map(-, i, s.shifts)`
is a valid index for `s.parent`, and `s.v[i, ...] == missing` otherwise.
Use `copy` to collect the values of a `ShiftedArray` into a normal `Array`.

# Examples

```jldoctest shiftedarray
julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
  missing
 1
 3
 5

julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
  missing
 1
 3
 5

julia> copy(s)
4-element Array{Union{Int64, Missings.Missing},1}:
  missing
 1
 3
 5

julia> v = reshape(1:16, 4, 4);

julia> s = ShiftedArray(v, (0, 2))
4×4 ShiftedArrays.ShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 missing  missing  1  5
 missing  missing  2  6
 missing  missing  3  7
 missing  missing  4  8

julia> shifts(s)
(0, 2)
```
"""
struct ShiftedArray{T, N, S<:AbstractArray} <: AbstractArray{Union{T, Missing}, N}
    parent::S
    shifts::NTuple{N, Int64}
end

ShiftedArray(v::AbstractArray{T, N}, n::NTuple{N, Int} = Tuple(0 for i in 1:N)) where {T, N} =
    ShiftedArray{T, N, typeof(v)}(v, n)

ShiftedArray(v::AbstractArray{T, N}, n) where {T, N} =
    ShiftedArray(v, _padded_tuple(n, N))

"""
    ShiftedVector{T, S<:AbstractArray}

Shorthand for `ShiftedArray{T, 1, S}`.
"""
const ShiftedVector{T, S<:AbstractArray} = ShiftedArray{T, 1, S}

ShiftedVector(v::AbstractVector, n = (0,)) = ShiftedArray(v, n)

Base.size(s::ShiftedArray) = Base.size(parent(s))

function Base.getindex(s::ShiftedArray{T, N, S}, x::Vararg{Int, N}) where {T, N, S<:AbstractArray}
    i = map(-, x, shifts(s))
    v = parent(s)
    if checkbounds(Bool, v, i...)
        @inbounds ret = v[i...]
    else
        ret = missing
    end
    ret
end

Base.parent(s::ShiftedArray) = s.parent

"""
    shifts(s::ShiftedArray)

Returns amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(s::ShiftedArray) = s.shifts
