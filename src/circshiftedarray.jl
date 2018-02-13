"""
    CircShiftedArray(parent::AbstractArray, shifts)

Custom `AbstractArray` object to store an `AbstractArray` `parent` circularly shifted by `shifts` steps (where `shifts` is
a `Tuple` with one `shift` value per dimension of `parent`).
Use `copy` to collect the values of a `CircShiftedArray` into a normal `Array`.

# Examples

```jldoctest circshiftedarray
julia> v = [1, 3, 5, 4];

julia> s = CircShiftedArray(v, (1,))
4-element ShiftedArrays.CircShiftedArray{Int64,1,Array{Int64,1}}:
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
    shifts::NTuple{N, Int64}
end

CircShiftedArray(v::AbstractArray{T, N}, n = Tuple(0 for i in 1:N)) where {T, N} = CircShiftedArray{T, N, typeof(v)}(v, n)

"""
    CircShiftedArray(parent::AbstractArray, n::Int; dim = 1)

Auxiliary method to create a `CircShiftedArray` shifted of `n` steps on dimension `dim`.

# Examples

```jldoctest circshiftedarray
julia> v = reshape(1:16, 4, 4);

julia> s = CircShiftedArray(v, 2; dim = 1)
4×4 ShiftedArrays.CircShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 3  7  11  15
 4  8  12  16
 1  5   9  13
 2  6  10  14

julia> shifts(s)
(2, 0)
```
"""
function CircShiftedArray(v::AbstractArray{T, N}, n::Int; dim = 1) where {T, N}
    tup = Tuple(i == dim ? n : 0 for i in 1:N)
    CircShiftedArray(v, tup)
end

"""
    CircShiftedVector{T, S<:AbstractArray}

Shorthand for `CircShiftedArray{T, 1, S}`.
"""
const CircShiftedVector{T, S<:AbstractArray} = CircShiftedArray{T, 1, S}

CircShiftedVector(v::AbstractVector{T}, n = (0,)) where {T} = CircShiftedArray(v, n)
CircShiftedVector(v::AbstractVector{T}, n::Int; dim = 1)  where {T} =
    CircShiftedArray(v, n::Int; dim = 1)

Base.size(s::CircShiftedArray) = Base.size(parent(s))


function _shifted_between(i, a, b, n)
    if i < a
        return _shifted_between(i+n, a, b, n)
    elseif i > b
        return _shifted_between(i-n, a, b, n)
    else
        return i
    end
end

function get_circshifted_index(ind, shift, range)
    a, b = extrema(range)
    n = length(range)
    _shifted_between(ind-shift, a, b, n)
end

function Base.getindex(s::CircShiftedArray{T, N, S}, x::Vararg{Int, N}) where {T, N, S<:AbstractArray}
    v = parent(s)
    i = map(get_circshifted_index, x, shifts(s), Compat.axes(v))
    v[i...]
end

function Base.setindex!(s::CircShiftedArray{T, N, S}, el, x::Vararg{Int, N}) where {T, N, S<:AbstractArray}
    v = parent(s)
    i = map(get_circshifted_index, x, shifts(s), Compat.axes(v))
    v[i...] = el
end

Base.parent(s::CircShiftedArray) = s.parent

"""
    shifts(s::CircShiftedArray)

Returns amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(s::CircShiftedArray) = s.shifts
