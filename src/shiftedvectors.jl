"""
    `ShiftedVector(v::AbstractVector, n)`

Custom `AbstractVector` object to store an `AbstractVector` `v` shifted by `n` steps.
For `s::ShiftedVector`, `s.v[i] == v[i + s.n]` if `i + s.n` is a valid index for `v`,
and `s.v[i] == missing` otherwise. Use `copy` to collect the values of a `ShiftedVector`
into a normal `Vector`.

# Examples

```jldoctest shiftedvector
julia> v = [1, 3, 5, 4];

julia> s = ShiftedVector(v, 1)
4-element WindowFunctions.ShiftedVector{Int64,Array{Int64,1}}:
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
struct ShiftedVector{T, S<:AbstractVector} <: AbstractVector{Union{T, Missing}}
    v::S
    n::Int64
end

ShiftedVector(v::AbstractVector{T}, n = 0) where {T} = ShiftedVector{T, typeof(v)}(v, n)

Base.size(s::ShiftedVector) = Base.size(s.v)

function Base.getindex(s::ShiftedVector, i::Int)
    i1 = i + s.n
    i1 in indices(s.v)[1] ? s.v[i1] : missing
end
