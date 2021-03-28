"""
    ft_center_diff(s [, dims])

Calculates how much the entries in each dimension must be shifted so that the
center frequency is at the Fourier center.
This function is internally used by `ShiftedArrays.fftshift` and `ShiftedArrays.ifftshift`.

# Examples
```jldoctest
julia> ShiftedArrays.ft_center_diff((4, 5, 6), (1, 2)) # Fourier center is at (2, 3, 0)
(2, 2, 0)

julia> ShiftedArrays.ft_center_diff((4, 5, 6), (1, 2, 3)) # Fourier center is at (2, 3, 4)
(2, 2, 3)
```
"""
function ft_center_diff(s::NTuple{N, T}, dims=ntuple(identity, Val(N))) where {N, T}
    return ntuple(i -> i ∈ dims ?  s[i] ÷ 2 : 0 , N)
end

"""
    fftshift(x [, dims])

Result is semantically equivalent to `AbstractFFTs.fftshift(A, dims)` but returns 
a `CircShiftedArray` instead. 

# Examples
```jldoctest
julia> ShiftedArrays.fftshift([1 0 0 0])
1×4 CircShiftedArray{Int64, 2, Matrix{Int64}}:
 0  0  1  0

julia> ShiftedArrays.fftshift([1 0 0; 0 0 0; 0 0 0])
3×3 CircShiftedArray{Int64, 2, Matrix{Int64}}:
 0  0  0
 0  1  0
 0  0  0

julia> ShiftedArrays.fftshift([1 0 0; 0 0 0; 0 0 0], (1,))
3×3 CircShiftedArray{Int64, 2, Matrix{Int64}}:
 0  0  0
 1  0  0
 0  0  0
```
"""
function fftshift(x::AbstractArray{T, N}, dims=ntuple(identity, Val(N))) where {T, N}
    ShiftedArrays.circshift(x, ft_center_diff(size(x), dims))
end

"""
    ifftshift(A [, dims])

Result is semantically equivalent to `AbstractFFTs.ifftshift(A, dims)` but returns 
a `CircShiftedArray` instead. 

# Examples
```jldoctest
julia> ShiftedArrays.ifftshift([0 0 1 0])
1×4 CircShiftedArray{Int64, 2, Matrix{Int64}}:
 1  0  0  0

julia> ShiftedArrays.ifftshift([0 0 0; 0 1 0; 0 0 0])
3×3 CircShiftedArray{Int64, 2, Matrix{Int64}}:
 1  0  0
 0  0  0
 0  0  0

julia> ShiftedArrays.ifftshift([0 1 0; 0 0 0; 0 0 0], (2,))
3×3 CircShiftedArray{Int64, 2, Matrix{Int64}}:
 1  0  0
 0  0  0
 0  0  0
```
"""
function ifftshift(x::AbstractArray{T, N}, dims=ntuple(identity, Val(N))) where {T, N}
    ShiftedArrays.circshift(x, map(-, ft_center_diff(size(x), dims)))
end
