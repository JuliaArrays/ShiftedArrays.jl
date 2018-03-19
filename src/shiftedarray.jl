_padded_tuple(v::AbstractArray{T, N}, n::NTuple{N, Int}) where {T, N} = n
_padded_tuple(v::AbstractArray{T, N}, n::Int) where {T, N} = _padded_tuple(v, (n,))
_padded_tuple(v::AbstractArray{T, N}, n) where {T, N} = Tuple(i <= length(n) ? n[i] : 0 for i in 1:N)

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
4-element ShiftedArrays.ShiftedArray{Int64,Missings.Missing,1,Array{Int64,1}}:
  missing
 1
 3
 5

julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedArrays.ShiftedArray{Int64,Missings.Missing,1,Array{Int64,1}}:
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
4×4 ShiftedArrays.ShiftedArray{Int64,Missings.Missing,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
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
    shifts::NTuple{N, Int64}
    default::M
end

const ShiftedAbstractArray{T, N} = ShiftedArray{T, <:Any, N, <:Any}

ShiftedArray(v::AbstractArray{T, N}, n = Tuple(0 for i in 1:N); default::M = missing) where {T, N, M} =
     ShiftedArray{T, M, N, typeof(v)}(v, _padded_tuple(v, n), default)

"""
    ShiftedVector{T, S<:AbstractArray}

Shorthand for `ShiftedArray{T, 1, S}`.
"""
const ShiftedVector{T, M, S<:AbstractArray} = ShiftedArray{T, M, 1, S}

ShiftedVector(v::AbstractVector, n = (0,); default = missing) = ShiftedArray(v, n; default = default)

Base.size(s::ShiftedArray) = Base.size(parent(s))

function Base.getindex(s::ShiftedArray{T, M, N, S}, x::Vararg{Int, N}) where {T, M, N, S<:AbstractArray}
    i = map(-, x, shifts(s))
    v = parent(s)
    if checkbounds(Bool, v, i...)
        @inbounds ret = v[i...]
    else
        ret = default(s)
    end
    ret
end

Base.parent(s::ShiftedArray) = s.parent

"""
    shifts(s::ShiftedArray)

Returns amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(s::ShiftedArray) = s.shifts

"""
    default(s::ShiftedArray)

Returns default value.
"""
default(s::ShiftedArray) = s.default

Base.checkbounds(::ShiftedArray, I...) = nothing
