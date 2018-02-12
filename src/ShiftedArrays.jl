__precompile__()
module ShiftedArrays

if VERSION<v"0.7.0-DEV"
    using Missings
end

export ShiftedArray, ShiftedVector, shifts
export CircShiftedArray, CircShiftedVector
export lag, lead
export reduce_vec, mapreduce_vec

include("shiftedarray.jl")
include("circshiftedarray.jl")
include("lag.jl")
include("reduce.jl")

end
