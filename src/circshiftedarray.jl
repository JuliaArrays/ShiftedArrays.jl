"""
    CircShiftedArray(parent::AbstractArray, shifts)

Custom `AbstractArray` object to store an `AbstractArray` `parent` circularly shifted by `shifts` steps (where `shifts` is
a `Tuple` with one `shift` value per dimension of `parent`). Note that `shift` is modified with a modulo operation and does
not store the passed value but instead a positive number which leads to an equivalent shift.
Use `copy` to collect the values of a `CircShiftedArray` into a normal `Array`.

# Examples

```jldoctest circshiftedarray
julia> v = [1, 3, 5, 4];

julia> s = CircShiftedArray(v, (1,))
4-element CircShiftedVector{Int64, Vector{Int64}}:
 4
 1
 3
 5

julia> copy(s)
4-element Vector{Int64}:
 4
 1
 3
 5
```
"""
struct CircShiftedArray{T, N, S<:AbstractArray} <: AbstractArray{T, N}
    parent::S
    # the field `shifts` stores the circular shifts modulo the size of the parent array
    shifts::NTuple{N, Int}
    function CircShiftedArray(p::AbstractArray{T, N}, n = ()) where {T, N}
        shifts = map(mod, padded_tuple(p, n), size(p))
        return new{T, N, typeof(p)}(p, shifts)
    end
end

"""
    CircShiftedVector{T, S<:AbstractArray}

Shorthand for `CircShiftedArray{T, 1, S}`.
"""
const CircShiftedVector{T, S<:AbstractArray} = CircShiftedArray{T, 1, S}

CircShiftedVector(v::AbstractVector, n = ()) = CircShiftedArray(v, n)

size(s::CircShiftedArray) = size(parent(s))
axes(s::CircShiftedArray) = axes(parent(s))

@inline function bringwithin(ind_with_offset::Int, ranges::AbstractUnitRange)
    return ifelse(ind_with_offset < first(ranges), ind_with_offset + length(ranges), ind_with_offset)
end

@inline function getindex(s::CircShiftedArray{T, N}, x::Vararg{Int, N}) where {T, N}
    @boundscheck checkbounds(s, x...)
    v, ind = parent(s), offset(shifts(s), x)
    i = map(bringwithin, ind, axes(s))
    return @inbounds v[i...]
end

@inline function setindex!(s::CircShiftedArray{T, N}, el, x::Vararg{Int, N}) where {T, N}
    @boundscheck checkbounds(s, x...)
    v, ind = parent(s), offset(shifts(s), x)
    i = map(bringwithin, ind, axes(s))
    @inbounds v[i...] = el
    return s
end

parent(s::CircShiftedArray) = s.parent

"""
    shifts(s::CircShiftedArray)

Return amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(s::CircShiftedArray) = s.shifts
