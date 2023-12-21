module CUDASupportExt
using CUDA 
using Adapt
using ShiftedArrays
using Base # to allow displaying such arrays without causing the single indexing CUDA error

Adapt.adapt_structure(to, x::CircShiftedArray{T, D}) where {T, D} = CircShiftedArray(adapt(to, parent(x)), shifts(x));
parent_type(::Type{CircShiftedArray{T, N, S}})  where {T, N, S} = S
Base.Broadcast.BroadcastStyle(::Type{T})  where {T<:CircShiftedArray} = Base.Broadcast.BroadcastStyle(parent_type(T))

# lets do this for the ShiftedArray type
Adapt.adapt_structure(to, x::ShiftedArray{T, M, N}) where {T, M, N} = ShiftedArray(adapt(to, parent(x)), shifts(x); default=ShiftedArrays.default(x));
function Base.Broadcast.BroadcastStyle(::Type{T})  where (T<: ShiftedArray{<:Any,<:Any,<:Any,<:CuArray})
    CUDA.CuArrayStyle{ndims(T)}()
end

# function Base.show(io::IO, mm::MIME"text/plain", cs::CircShiftedArray) 
#     CUDA.@allowscalar invoke(Base.show, Tuple{IO, typeof(mm), AbstractArray}, io, mm, cs) 
# end

# function Base.show(io::IO, mm::MIME"text/plain", cs::ShiftedArray) 
#     CUDA.@allowscalar invoke(Base.show, Tuple{IO, typeof(mm), AbstractArray}, io, mm, cs) 
# end
end