"""
    ShiftedArray(v::AbstractArray, n)

Custom `AbstractArray` object to store an `AbstractArray` `v` shifted by `n` steps in the
first indexing dimension.
For `s::ShiftedArray`, `s.v[i, ...] == v[i + s.n, ...]` if `(i + s.n, ...)` is a valid index for `v`,
and `s.v[i, ...] == missing` otherwise. Use `copy` to collect the values of a `ShiftedArray`
into a normal `Array`.

# Examples

```jldoctest shiftedarray
julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, 1)
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
 3
 5
 4
  missing

julia> copy(s)
4-element Array{Union{Int64, Missings.Missing},1}:
 3
 5
 4
  missing
```
"""
struct ShiftedArray{T, N, S<:AbstractArray} <: AbstractArray{Union{T, Missing}, N}
    v::S
    n::Int64
end

ShiftedArray(v::AbstractArray{T, N}, n = 0) where {T, N} = ShiftedArray{T, N, typeof(v)}(v, n)

const ShiftedVector{T, S<:AbstractArray} = ShiftedArray{T, 1, S}

ShiftedVector(v::AbstractVector{T}, n = 0) where {T} = ShiftedVector{T, typeof(v)}(v, n)

Base.size(s::ShiftedArray) = Base.size(s.v)

function Base.getindex(s::ShiftedArray{T, N, S}, x::Vararg{Int, N}) where {T, N, S<:AbstractArray}
    i = first(x) + s.n
    l = Base.tail(x)
    i in indices(parent(s))[1] ? parent(s)[i, l...] : missing
end

Base.parent(s::ShiftedArray) = s.v

"""
    indexshift(s::ShiftedArray)

Returns amount by which `s` is shifted compared to `parent(s)`.
"""
indexshift(s::ShiftedArray) = s.n
