convert(args...; kwargs...) = Base.convert(args...; kwargs...)

function convert(::Type{<:Array}, ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    v = VectorOfArray([view(s, I...) for s in ss])
    Array(v)
end

function convert(::Type{<:OffsetArray}, ss::AbstractArray{<:ShiftedAbstractArray{<:Any, N}}, I::Vararg{<:AbstractArray, N}) where N
    m = convert(Array, ss, I...)
    OffsetArray(m, I..., last(Compat.axes(m)))
end
