module WindowFunctions

using Missings

export ShiftedVector
export lag, lead

include("ShiftedVector.jl")
include("lag.jl")

end
