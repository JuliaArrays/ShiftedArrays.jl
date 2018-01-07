module WindowFunctions

using Missings

export ShiftedVector
export lag, lead

include("shiftedvectors.jl")
include("lag.jl")

end
