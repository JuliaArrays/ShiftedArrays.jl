module ShiftedArrays

using Missings

export ShiftedArray, ShiftedVector, indexshift
export lag, lead

include("shiftedarray.jl")
include("lag.jl")

end
