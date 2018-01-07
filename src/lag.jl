lag(v::AbstractVector, n = 1) = ShiftedVector(v, -n)

lead(v::AbstractVector, n = 1) = ShiftedVector(v, n)