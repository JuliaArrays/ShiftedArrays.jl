function to_array(ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    v = VectorOfArray([view(s, I...) for s in ss])
    Array(v)
end

function to_offsetarray(ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    m = to_array(ss, I...)
    OffsetArray(m, I..., last(Compat.axes(m)))
end
