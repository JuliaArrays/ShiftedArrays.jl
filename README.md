# WindowFunctions

[![Build Status](https://travis-ci.org/piever/WindowFunctions.jl.svg?branch=master)](https://travis-ci.org/piever/WindowFunctions.jl)

[![codecov.io](http://codecov.io/github/piever/WindowFunctions.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/WindowFunctions.jl?branch=master)

Implementation of window functions for data manipulations. A window function is a function that takes as input a vector of `n` elements and return a vector of `n`. This package is an attempt to collect window functions that are useful for data manipulations but have not yet been implemented in Julia.

## Shifting the data

Two operation are provided for lazily shifting vectors: `lag` and `lead`.

```julia
julia> v = [1, 3, 5, 4];

julia> lag(v)
4-element WindowFunctions.ShiftedVector{Int64,Array{Int64,1}}:
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
4-element WindowFunctions.ShiftedVector{Int64,Array{Int64,1}}:
  missing
  missing
 1       
 3 
```

Use `copy` to collect the shifted data into an `Array`:

```julia
julia> copy(s)
4-element Array{Union{Int64, Missings.Missing},1}:
  missing
  missing
 1       
 3 
```

`lead` is the analogous of `lag` but shifts in the opposite direction:

```julia
julia> v = [1, 3, 5, 4];

julia> lead(v)
4-element WindowFunctions.ShiftedVector{Int64,Array{Int64,1}}:
 3       
 5       
 4       
  missing
```