lag(v::AbstractVector, n = 1) = ShiftedVector(v, -n)

lead(v::AbstractVector, n = 1) = ShiftedVector(v, n)

lazyshift(v::AbstractVector, n) = ShiftedVector(v, n)