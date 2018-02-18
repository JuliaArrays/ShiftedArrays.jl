__precompile__()
module ShiftedArrays

using Missings

using Compat

import Base: reduce, mapreduce
export ShiftedArray, ShiftedVector, shifts, default
export CircShiftedArray, CircShiftedVector
export lag, lead
export reduce_vec, mapreduce_vec

include("shiftedarray.jl")
include("circshiftedarray.jl")
include("lag.jl")
include("circshift.jl")
include("reduce.jl")

end
