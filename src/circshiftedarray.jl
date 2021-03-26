"""
    CircShiftedArray(parent::AbstractArray, shifts)

Custom `AbstractArray` object to store an `AbstractArray` `parent` circularly shifted by `shifts` steps (where `shifts` is
a `Tuple` with one `shift` value per dimension of `parent`).
Use `copy` to collect the values of a `CircShiftedArray` into a normal `Array`.

# Examples

```jldoctest circshiftedarray
julia> v = [1, 3, 5, 4];

julia> s = CircShiftedArray(v, (1,))
4-element CircShiftedArray{Int64,1,Array{Int64,1}}:
 4
 1
 3
 5

julia> copy(s)
4-element Array{Int64,1}:
 4
 1
 3
 5
```
"""
struct CircShiftedArray{T, N, S<:AbstractArray} <: AbstractArray{T, N}
    parent::S
    shifts::NTuple{N, Int}
    function CircShiftedArray(p::AbstractArray{T, N}, n = Tuple(0 for i in 1:N)) where {T, N}
        @assert all(step(x) == 1 for x in axes(p))
        new{T, N, typeof(p)}(p, _padded_tuple(p, n))
    end
end

"""
    CircShiftedVector{T, S<:AbstractArray}

Shorthand for `CircShiftedArray{T, 1, S}`.
"""
const CircShiftedVector{T, S<:AbstractArray} = CircShiftedArray{T, 1, S}

CircShiftedVector(v::AbstractVector, n = (0,)) = CircShiftedArray(v, n)

size(s::CircShiftedArray) = size(parent(s))


@inline function bringwithin(idx::Int, range::AbstractRange)
    t = mod(idx - first(range), last(range))
    return first(range) + t 
end

@inline bringwithin(idxs::Tuple, ranges::Tuple) = bringwithin.(idxs, ranges)

@inline bringwithin(idxs::Tuple{}, ranges::Tuple{}) = ()

"""
    bringwithin(idx, idx2)

Moves the indices or index in `idx` into the interval covered by `idx2`

# Example
```jldoctest
julia> ShiftedArrays.bringwithin(1, 1:10)
1

julia> ShiftedArrays.bringwithin(-1, 1:10)
9
```
"""
bringwithin



@inline function getindex(s::CircShiftedArray{T, N}, x::Vararg{Int, N}) where {T, N}
    v = parent(s)
    @boundscheck checkbounds(v, x...)
    ind = offset(shifts(s), x)

    i = bringwithin(ind, axes(v))
    @inbounds ret = v[i...]
    ret
end

@inline function setindex!(s::CircShiftedArray{T, N}, el, x::Vararg{Int, N}) where {T, N}
    v = parent(s)
    @boundscheck checkbounds(v, x...)
    ind = offset(shifts(s), x)
    i = bringwithin(ind, axes(v))
    @inbounds v[i...] = el
end

parent(s::CircShiftedArray) = s.parent

"""
    shifts(s::CircShiftedArray)

Returns amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(s::CircShiftedArray) = s.shifts

# checkbounds(::CircShiftedArray, I...) = nothing
# checkbounds(::Type{Bool}, ::CircShiftedArray, I...) = true
