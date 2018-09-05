"""
`to_array(ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N`

Collect a `AbstractArray` of `ShiftedArrays` into a normal `Array`.
The output `Array` first few dimensions will be indexed by `I` (though starting from `1`)
and the last one will correspond to the index of the `ShiftedArray` within the `AbstractArray` of `ShiftedArrays`.
"""
function to_array(ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    v = VectorOfArray([view(s, I...) for s in ss])
    Array(v)
end

"""
`to_offsetarray(ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N`

Collect a `AbstractArray` of `ShiftedArrays` into an `OffsetArray`.
The output `Array` first few dimensions will be indexed by `I` (though starting from `1`)
and the last one will correspond to the index of the `ShiftedArray` within the `AbstractArray` of `ShiftedArrays`.
"""
function to_offsetarray(ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    m = to_array(ss, I...)
    OffsetArray(m, I..., last(Compat.axes(m)))
end
