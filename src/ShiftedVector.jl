struct ShiftedVector{T, S<:AbstractVector} <: AbstractVector{Union{T, Missing}}
    v::S
    n::Int64
end
ShiftedVector(v::AbstractVector{T}, n) where {T} = ShiftedVector{T, typeof(v)}(v, n)

isinbounds(s::ShiftedVector, i) = (i + s.n) in indices(s.v)[1] 

Base.size(s::ShiftedVector) = Base.size(s.v)

Base.getindex(s::ShiftedVector, i::Int)	= isinbounds(s, i) ? s.v[i + s.n] : missing

Base.setindex!(s::ShiftedVector, el, i::Int) = isinbounds(s, i) && setindex!(s.v, el, i + s.n)

