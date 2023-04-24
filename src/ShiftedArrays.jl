module ShiftedArrays

import Base: checkbounds, getindex, setindex!, parent, size, axes
export ShiftedArray, ShiftedVector, shifts, default
export CircShiftedArray, CircShiftedVector

include("shiftedarray.jl")
include("circshiftedarray.jl")
include("lag.jl")
include("circshift.jl")
include("fftshift.jl")

end
