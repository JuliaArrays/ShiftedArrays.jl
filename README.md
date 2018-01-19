# ShiftedArrays

[![Build Status](https://travis-ci.org/piever/ShiftedArrays.jl.svg?branch=master)](https://travis-ci.org/piever/ShiftedArrays.jl)

[![codecov.io](http://codecov.io/github/piever/ShiftedArrays.jl/coverage.svg?branch=master)](http://codecov.io/github/piever/ShiftedArrays.jl?branch=master)

Implementation of shifted arrays.

## Shifted Arrays

A `ShiftedArray` is a lazy view of an Array, shifted on its first indexing dimension by a constant value `n`.

```julia
julia> v = reshape(1:16, 4, 4)
4×4 Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}:
 1  5   9  13
 2  6  10  14
 3  7  11  15
 4  8  12  16

julia> s = ShiftedArray(v, (2, 0))
4×4 ShiftedArrays.ShiftedArray{Int64,2,Base.ReshapedArray{Int64,2,UnitRange{Int64},Tuple{}}}:
 3         7         11         15       
 4         8         12         16       
  missing   missing    missing    missing
  missing   missing    missing    missing
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

Use `copy` to collect the shifted data into an `Array`:

```julia
julia> copy(s)
4×4 Array{Union{Int64, Missings.Missing},2}:
 3         7         11         15       
 4         8         12         16       
  missing   missing    missing    missing
  missing   missing    missing    missing
```

If you only need to shift in one dimension, you can use the commodity method:

```julia
ShiftedArray(v, n; dim = 1)
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

## Reducing your data

A common pattern, when working with a time dependent variable is to align all vectors on important events and then compute some relevant summary functions (`sum`, `mean`, `std`, etc) or reduce the data using a binary function (`+`, `*`, etc...).

Let's say our data is the vector:

```julia
data = [1, 3, 5, 6, 7, 9, 16, 2, 3, 4, 7]
```

and our relevant events happen at times:

```julia
times = [2, 7, 9]
```

Then we should first compute the list of `ShiftedArrays`:

```julia
julia> ss = ShiftedArray.((data,), times)
3-element Array{ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}},1}:
 Union{Int64, Missings.Missing}[5, 6, 7, 9, 16, 2, 3, 4, 7, missing, missing]                                         
 Union{Int64, Missings.Missing}[2, 3, 4, 7, missing, missing, missing, missing, missing, missing, missing]            
 Union{Int64, Missings.Missing}[4, 7, missing, missing, missing, missing, missing, missing, missing, missing, missing]
```

Then to compute sum of the values of `data` in a range of `-1:2` aligned around `times`, we can simply do:

```julia
julia> reduce(+, ss, -1:2)
4-element Array{Int64,1}:
 12
 22
 11
 16
```

`mapreduce` allows applying a function before the reducing operator. For example, to compute the sum of squares we'd d:

```julia
julia> mapreduce(i->i^2, +, ss, -1:2)
4-element Array{Int64,1}:
  86
 274
  45
  94
```

Vectorial summary functions (`mean`, `std`) can also be used, provided they accept an iterator as argument, example:

```julia
julia> reduce_vec(std, ss, -1:2)
4-element Array{Float64,1}:
 4.3589
 7.50555
 1.52753
 2.08167
```

As before, `mapreduce_vec` allows passing a preprocessing function before reducing, for example to compute the mean of the squares, simply run:

```julia
julia> mapreduce_vec(i->i^2, mean, ss, -1:2)
4-element Array{Float64,1}:
 28.6667
 91.3333
 15.0   
 31.3333
```
