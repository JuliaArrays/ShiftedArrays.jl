"""
`to_array(ss::AbstractArray{<:AbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N`

Collect a `AbstractArray` of `AbstractArrays` into a normal `Array` selecting indices `I` (can take negative values if inner `AbstractArrays` allow it).
The output `Array` first few dimensions will be indexed by `I` (though starting from `1`)
and the last one will correspond to the index of the inner `AbstractArray` within the `AbstractArray` of `AbstractArrays`.
"""
function to_array(ss::AbstractArray{<:AbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    v = VectorOfArray([view(s, I...) for s in ss])
    Array(v)
end

"""
`to_offsetarray(ss::AbstractArray{<:AbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N`

Collect a `AbstractArray` of `ShiftedArrays` into an `OffsetArray` selecting indices `I` (can take negative values if inner `AbstractArrays` allow it).
The output `OffsetArray` first few dimensions will be indexed by `I`
and the last one will correspond to the index of the inner `AbstractArray` within the `AbstractArray` of `AbstractArrays`.
"""
function to_offsetarray(ss::AbstractArray{<:AbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    m = to_array(ss, I...)
    OffsetArray(m, I..., last(axes(m)))
end
