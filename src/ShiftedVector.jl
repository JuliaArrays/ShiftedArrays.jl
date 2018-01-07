struct ShiftedVector{T, S<:AbstractVector} <: AbstractVector{Union{T, Missing}}
    v::S
    n::Int64
end
ShiftedVector(v::AbstractVector{T}, n) where {T} = ShiftedVector{T, typeof(v)}(v, n)

Base.size(s::ShiftedVector) = Base.size(s.v)

function Base.getindex(s::ShiftedVector, i::Int)
    i1 = i + s.n
    i1 in indices(s.v)[1] ? s.v[i1] : missing
end
