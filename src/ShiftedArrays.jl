module ShiftedArrays

using Missings

export ShiftedArray, ShiftedVector, shifts
export lag, lead
export reduce_vec, mapreduce_vec

include("shiftedarray.jl")
include("lag.jl")
include("reduce.jl")

end
