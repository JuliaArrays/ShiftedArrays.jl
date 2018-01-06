module WindowFunctions

using Missings

export ShiftedVector
export lag, lead, lazyshift

include("ShiftedVector.jl")
include("lag.jl")

end
