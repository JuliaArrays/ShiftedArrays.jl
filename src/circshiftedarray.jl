"""
    ShiftedArray(parent::AbstractArray, shifts)

Custom `AbstractArray` object to store an `AbstractArray` `parent` circularly shifted
by `shifts` steps (where `shifts` is a `Tuple` with one `shift` value per dimension of `parent`).
Use `copy` or `collect` to collect the values of a `ShiftedArray` into a normal `Array`.

!!! note
    `shift` is modified with a modulo operation and does not store the passed value
    but instead a nonnegative number which leads to an equivalent shift.

!!! note
    If `parent` is itself a `ShiftedArray`, the constructor does not nest
    `ShiftedArray` objects but rather combines the shifts additively.

# Examples

```jldoctest shiftedarray
julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedVector{Int64, Vector{Int64}, Tuple{1}, Missing}:
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
```
"""
const CircShiftedArray{T, N, A<:AbstractArray} = ShiftedArray{T, N, A, CircShift} 
CircShiftedArray(p::AbstractArray, n=()) = ShiftedArray(p, map(mod, padded_tuple(p, n), size(p)); default=CircShift())
function CircShiftedArray(p::ShiftedArray, n=()) 
    ns = map(mod, padded_tuple(p, n) .+ shifts(p), size(p))
    if all(ns.==0)
        return p.parent
    else
        return ShiftedArray(p.parent, ns; default=CircShift())
    end
end

"""
    CircShiftedVector{T, A<:AbstractArray}

Shorthand for `ShiftedArray{T, 1, A}`.
"""
const CircShiftedVector{T, A<:AbstractArray} = ShiftedVector{T, A, CircShift}

CircShiftedVector(v::AbstractVector, n = ()) = CircShiftedArray(v, n)
# CircShiftedVector(v::AbstractVector, s = ()) = ShiftedArray(v, s)
# CircShiftedVector(v::AbstractVector, s::Number) = ShiftedArray(v, (s,))

has_circ_type(a::CircShiftedArray) = true


# mod1 avoids first subtracting one and then adding one
@inline function Base.getindex(csa::CircShiftedArray{T,N,A}, i::Vararg{Int,N}) where {T,N,A} 
    # @show "gi circ"
    getindex(csa.parent, (mod1(i[j]-shifts(csa)[j], size(csa.parent, j)) for j in 1:N)...)
end

@inline function Base.setindex!(csa::CircShiftedArray{T,N,A}, v, i::Int) where {T,N,A}
    # @show "si circ"
    setindex!(csa.parent, v, i)
end

@inline function Base.setindex!(csa::CircShiftedArray{T,N,A}, v, i::Vararg{Int,N}) where {T,N,A}
    # @show "si circ"
    #(setindex!(csa.parent, v, (mod1(i[j]-to_tuple(S)[j], size(csa.parent, j)) for j in 1:N)...); v)
    setindex!(csa.parent, v, (mod1(i[j]-shifts(csa)[j], size(csa.parent, j)) for j in 1:N)...)
    csa
end

# for speed reasons use the optimized version in Base for actually perfoming the circshift in this case:
Base.collect(csa::CircShiftedArray{T,N,A}) where {T,N,A} = Base.circshift(csa.parent, shifts(csa))

# this is not really fully in place, but the only way to emulate the reverse! function
function Base.reverse!(csa::CircShiftedArray; dims=:)
    tmp = Base.reverse(csa.parent; dims=dims)
    # keep the old shift but compensate by an appropriate circshift
    Base.circshift!(csa.parent, tmp, -2 .* shifts(csa))
    return csa
end

# CircShiftedArray(v::AbstractArray, s::Number) = CircShiftedArray(v, map(mod, padded_tuple(v, s), size(v)))
