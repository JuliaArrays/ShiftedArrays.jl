"""
    reduce(op, ss::AbstractArray{<:ShiftedVector}, args...; default = missing, filter = t->true, dropmissing = true)

Align all vectors in `ss`. For each of the indices in `args`, extract the collection of
elements corresponding to that index and reduce using `op`. `op` can be any binary reduction
function. Indices for which the iterable is empty will return `default`.

# Examples

```jldoctest reduce
julia> v = [1, 3, 5, 9, 6, 7];

julia> ss = ShiftedArray.((v,), [-2, -4])
2-element Array{ShiftedArrays.ShiftedArray{Int64,Missing,1,Array{Int64,1}},1}:
 Union{Int64, Missing}[5, 9, 6, 7, missing, missing]
 Union{Int64, Missing}[6, 7, missing, missing, missing, missing]

julia> reduce(+, ss, 1:2)
2-element Array{Int64,1}:
 11
 16

julia> reduce(+, ss, -5:2)
8-element Array{Any,1}:
   missing
   missing
  1
  3
  6
 12
 11
 16
```
"""
function reduce end


"""
    mapreduce(g, op, ss::AbstractArray{<:ShiftedVector}, args...; default = missing, filter = t->true, dropmissing = true)

Align all vectors in `ss`. For each of the indices in `args`, extract the collection of
elements corresponding to that index, apply `g` and reduce using `op`. `op` can be any binary reduction
function. Indices for which the iterable is empty will return `default`.

# Examples

```jldoctest mapreduce
julia> v = [1, 3, 5, 9, 6, 7];

julia> ss = ShiftedArray.((v,), [-2, -4])
2-element Array{ShiftedArrays.ShiftedArray{Int64,Missing,1,Array{Int64,1}},1}:
 Union{Int64, Missing}[5, 9, 6, 7, missing, missing]
 Union{Int64, Missing}[6, 7, missing, missing, missing, missing]

julia> mapreduce(t -> t^2, +, ss, 1:2)
2-element Array{Int64,1}:
 61
 130

julia> mapreduce(t -> t^2, +, ss, -5:2)
8-element Array{Any,1}:
    missing
    missing
   1
   9
  26
  90
  61
 130
```
"""
function mapreduce end

"""
    reduce_vec(f, ss::AbstractArray{<:ShiftedVector}, args...; default = missing, filter = t->true, dropmissing = true)

Align all vectors in `ss`. For each of the indices in `args`, extract the collection of
elements corresponding to that index and reduce using `f`. `f` is any function that
takes an iterable as input and outputs a scalar, such as `mean`. Indices for which the
iterable is empty will return `default`.

# Examples

```jldoctest reduce_vec
julia> v = [1, 3, 5, 9, 6, 7];

julia> ss = ShiftedArray.((v,), [-2, -4])
2-element Array{ShiftedArrays.ShiftedArray{Int64,Missing,1,Array{Int64,1}},1}:
 Union{Int64, Missing}[5, 9, 6, 7, missing, missing]
 Union{Int64, Missing}[6, 7, missing, missing, missing, missing]

julia> reduce_vec(mean, ss, 1:2)
2-element Array{Float64,1}:
 5.5
 8.0

julia> reduce_vec(mean, ss, -5:2)
8-element Array{Any,1}:
  missing
  missing
 1.0
 3.0
 3.0
 6.0
 5.5
 8.0
```
"""
function reduce_vec end

"""
    mapreduce_vec(g, f, ss::AbstractArray{<:ShiftedVector}, args...; default = missing, filter = t->true, dropmissing = true)

Align all vectors in `ss`. For each of the indices in `args`, extract the collection of
elements corresponding to that index, apply `g` and reduce using `f`. `f` is any function that
takes an iterable as input and outputs a scalar, such as `mean`. Indices for which the
iterable is empty will return `default`.

# Examples

```jldoctest mapreduce_vec
julia> v = [1, 3, 5, 9, 6, 7];

julia> ss = ShiftedArray.((v,), [-2, -4])
2-element Array{ShiftedArrays.ShiftedArray{Int64,Missing,1,Array{Int64,1}},1}:
 Union{Int64, Missing}[5, 9, 6, 7, missing, missing]
 Union{Int64, Missing}[6, 7, missing, missing, missing, missing]

julia> mapreduce_vec(log, mean, ss, 1:2)
2-element Array{Float64,1}:
 1.7006
 2.07157

julia> mapreduce_vec(log, mean, ss, -5:2)
8-element Array{Any,1}:
  missing
  missing
 0.0
 1.09861
 0.804719
 1.64792
 1.7006
 2.07157
```
"""
function mapreduce_vec end

mapreduce_vec(g, f, itr) = f(g(x) for x in itr)

for (_mapreduce, mapreduce, reduce) in [(:_mapreduce, :mapreduce, :reduce), (:_mapreduce_vec, :mapreduce_vec, :reduce_vec)]
    @eval begin
        # auxiliary method to filter away missings and return a default if no values are found
        function ($_mapreduce)(g, op, itr; default = missing, filter = t->true, dropmissing = true)
            missingfree_itr = dropmissing ? skipmissing(itr) : itr
            filtered_itr = Iterators.filter(filter, missingfree_itr)
            isempty(filtered_itr) ? default : ($mapreduce)(g, op, filtered_itr)
        end

        # align the shifted arrays and apply _mapreduce
        function ($mapreduce)(g, f, ss::AbstractArray{<:ShiftedArray{<:Any, <:Any, N}}, args::Vararg{<:AbstractArray, N}; kwargs...) where{N}
            inds = Base.product(args...)
            [($_mapreduce)(g, f, (s[CartesianIndex(i)] for s in ss); kwargs...) for i in inds]
        end

        # define corresponding reduce methods
        ($reduce)(op, ss::AbstractArray{<:ShiftedArray{<:Any, <:Any, N}}, args::Vararg{<:AbstractArray, N}; kwargs...) where{N} =
            ($mapreduce)(identity, op, ss, args...; kwargs...)
    end
end
