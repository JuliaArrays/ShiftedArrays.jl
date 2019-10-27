module ShiftedArrays

import Base: checkbounds, getindex, setindex!, parent, size
export ShiftedArray, ShiftedVector, shifts, default
export CircShiftedArray, CircShiftedVector
export lag, lead
export reduce_vec, mapreduce_vec

include("shiftedarray.jl")
include("circshiftedarray.jl")
include("lag.jl")
include("circshift.jl")

end
