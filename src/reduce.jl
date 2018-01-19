lazymap(f, xs) = (f(x) for x in xs)

"""
    reduce(op, ss::AbstractArray{<:ShiftedVector}, args...)

Align all vectors in `ss`. For each of the indices in `args`, extract the collection of
elements corresponding to that index and reduce using `op`. `op` can be any binary reduction
function.

# Examples

```jldoctest reduce
julia> v = [1, 3, 5, 9, 6, 7];

julia> ss = ShiftedArray.((v,), [2, 4])
2-element Array{ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}},1}:
 Union{Int64, Missings.Missing}[5, 9, 6, 7, missing, missing]
 Union{Int64, Missings.Missing}[6, 7, missing, missing, missing, missing]

julia> reduce(+, ss, 1:2)
2-element Array{Int64,1}:
 11
 16
```
"""
Base.reduce(op, ss::AbstractArray{<:ShiftedArray}, args...) =
    mapreduce(identity, op, ss, args...)

function Base.mapreduce(g, op, ss::AbstractArray{<:ShiftedArray}, args...)
    inds = Base.product(args...)
    [mapreduce(g, op, skipmissing(s[CartesianIndex(i)] for s in ss)) for i in inds]
end

"""
    reduce_vec(f, ss::AbstractArray{<:ShiftedVector}, args...)

Align all vectors in `ss`. For each of the indices in `args`, extract the collection of
elements corresponding to that index and reduce using `f`. `f` is any function that
takes an iterable as input and outputs a scalar, such as `mean`.

# Examples

```jldoctest reduce_vec
julia> v = [1, 3, 5, 9, 6, 7];

julia> ss = ShiftedArray.((v,), [2, 4])
2-element Array{ShiftedArrays.ShiftedArray{Int64,1,Array{Int64,1}},1}:
 Union{Int64, Missings.Missing}[5, 9, 6, 7, missing, missing]
 Union{Int64, Missings.Missing}[6, 7, missing, missing, missing, missing]

julia> reduce_vec(mean, ss, 1:2)
2-element Array{Float64,1}:
 5.5
 8.0
```
"""
reduce_vec(f, ss::AbstractArray{<:ShiftedArray}, args...) =
    mapreduce_vec(g, f, ss, args...)

function mapreduce_vec(f, ss::AbstractArray{<:ShiftedArray}, args...)
    inds = Base.product(args...)
    [f(lazymap(g, skipmissing(s[CartesianIndex(i)] for s in ss))) for i in inds]
end
