# ShiftedArrays

[![Build Status](https://travis-ci.org/piever/ShiftedArrays.jl.svg?branch=master)](https://travis-ci.org/piever/ShiftedArrays.jl)
[![codecov.io](http://codecov.io/github/piever/ShiftedArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/ShiftedArrays.jl?branch=master)

Implementation of shifted arrays.

## Shifted Arrays

A `ShiftedArray` is a lazy view of an Array, shifted on some or all of his indexing dimensions by some constant values.

```julia
julia> v = reshape(1:16, 4, 4)
4×4 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  5   9  13
 2  6  10  14
 3  7  11  15
 4  8  12  16

 julia> s = ShiftedArray(v, (2, 0))
 4×4 ShiftedArrays.ShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
   missing   missing    missing    missing
   missing   missing    missing    missing
  1         5          9         13       
  2         6         10         14  
```

The parent Array as well as the amount of shifting can be recovered with `parent` and `shifts` respectively.

```julia
julia> parent(s)
4×4 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  5   9  13
 2  6  10  14
 3  7  11  15
 4  8  12  16

julia> shifts(s)
(2, 0)
```

`shifts` returns a `Tuple`, where the n-th element corresponds to the shift on the n-th dimension of the parent `Array`.

Use `copy` to collect the shifted data into an `Array`:

```julia
julia> copy(s)
4×4 Array{Union{Int64, Missing},2}:
  missing   missing    missing    missing
  missing   missing    missing    missing
 1         5          9         13       
 2         6         10         14   
```

If you pass an integer, it will shift in the first dimension:

```julia
julia> ShiftedArray(v, 1)
4×4 ShiftedArrays.ShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
  missing   missing    missing    missing
 1         5          9         13
 2         6         10         14
 3         7         11         15
```

A custom default value (other than `missing`) can be provided with the `default` keyword:

```julia
julia> ShiftedArray([1.2, 3.1, 4.5], 1, default = NaN)
3-element ShiftedArrays.ShiftedArray{Float64,Float64,1,Array{Float64,1}}:
 NaN
   1.2
   3.1
```

### Out of bound indexes

The bound check is performed only on the parent `Array`, not on the `ShiftedArray`, so for example:

```julia
julia> ShiftedArray([1.2, 3.1, 4.5], 1, default = NaN)[-2:3]
6-element Array{Float64,1}:
 NaN
 NaN
 NaN
 NaN
   1.2
   3.1
```

## Shifting the data

Using the `ShiftedArray` type, this package provides two operations for lazily shifting vectors: `lag` and `lead`.

```julia
julia> v = [1, 3, 5, 4];

julia> lag(v)
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
  missing
 1       
 3       
 5       

julia> v .- lag(v) # compute difference from previous element without unnecessary allocations
4-element Array{Any,1}:
   missing
  2       
  2       
 -1       

julia> s = lag(v, 2) # shift by more than one element
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
  missing
  missing
 1       
 3
```

`lead` is the analogous of `lag` but shifts in the opposite direction:

```julia
julia> v = [1, 3, 5, 4];

julia> lead(v)
4-element ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}}:
 3       
 5       
 4       
  missing
```

## Shifting the data circularly

Julia Base provides a function `circshift` to shift the data circularly. However this function
creates a copy of the vector, which may be unnecessary if the rotated vector is to be used only once.
This package provides the `CircShiftedArray` type, which is a lazy view of an array
shifted on some or all of his indexing dimensions by some constant values.

Our implementation of `circshift` relies on them to avoid copying:

```julia
julia> w = reshape(1:16, 4, 4);

julia> s = ShiftedArrays.circshift(w, (1, -1))
4×4 ShiftedArrays.CircShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 8  12  16  4
 5   9  13  1
 6  10  14  2
 7  11  15  3
```

As usual, you can `copy` the result to have a normal `Array`:

```julia
julia> copy(s)
4×4 Array{Int64,2}:
 8  12  16  4
 5   9  13  1
 6  10  14  2
 7  11  15  3
```

