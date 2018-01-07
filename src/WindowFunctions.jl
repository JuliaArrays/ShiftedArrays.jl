module WindowFunctions

using Missings

export ShiftedVector
export lag, lead, lazyshift

include("shiftedvector.jl")
include("lag.jl")

end
