export CircShiftedArray
using Base

"""
    CircShiftedArray(parent::AbstractArray, shifts)

Custom `AbstractArray` object to store an `AbstractArray` `parent` circularly shifted
by `shifts` steps (where `shifts` is a `Tuple` with one `shift` value per dimension of `parent`).
Use `copy` or `collect` to collect the values of a `CircShiftedArray` into a normal `Array`.

!!! note
    `shift` is modified with a modulo operation and does not store the passed value
    but instead a nonnegative number which leads to an equivalent shift.

!!! note
    If `parent` is itself a `CircShiftedArray`, the constructor does not nest
    `CircShiftedArray` objects but rather combines the shifts additively.

# Examples

```jldoctest circshiftedarray
julia> v = [1, 3, 5, 4];

julia> s = CircShiftedArray(v, (1,))
4-element CircShiftedVector{Int64, Vector{Int64}}:
 4
 1
 3
 5

julia> copy(s)
4-element Vector{Int64}:
 4
 1
 3
 5
```
"""
struct CircShiftedArray{T, N, A<:AbstractArray{T,N}, myshift<:Tuple} <: AbstractArray{T,N}
    parent::A    

    function CircShiftedArray(p::A, n=())::CircShiftedArray{T,N,A,NTuple{N,Int}} where {T,N,A<:AbstractArray{T,N}}
        myshifts = map(mod, padded_tuple(p, n), size(p))
        ws = wrapshift(myshifts, size(p))
        new{T,N,A, Tuple{ws...}}(p)
    end
    # if a CircShiftedArray is wrapped in a CircShiftedArray, only a single CSA results 
    function CircShiftedArray(p::CircShiftedArray{T,N,A,S}, n=())::CircShiftedArray{T,N,A,NTuple{N,Int}} where {T,N,A,S}
        myshifts = map(mod, padded_tuple(p, n), size(p))
        ws = wrapshift(myshifts .+ to_tuple(shifts(typeof(p))), size(p))
        new{T,N,A, Tuple{ws...}}(p.parent)
    end
end

"""
    CircShiftedVector{T, S<:AbstractArray}

Shorthand for `CircShiftedArray{T, 1, S}`.
"""
const CircShiftedVector{T, S<:AbstractArray} = CircShiftedArray{T, 1, S}

CircShiftedVector(v::AbstractVector, n = ()) = CircShiftedArray(v, n)

# we keep this for compatability reasons
@inline function bringwithin(ind_with_offset::Int, ranges::AbstractUnitRange)
    return ifelse(ind_with_offset < first(ranges), ind_with_offset + length(ranges), ind_with_offset)
end

# wraps shifts into the range 0...N-1
wrapshift(shift::NTuple, dims::NTuple) = ntuple(i -> mod(shift[i], dims[i]), length(dims))
# wraps indices into the range 1...N
wrapids(shift::NTuple, dims::NTuple) = ntuple(i -> mod1(shift[i], dims[i]), length(dims))
invert_rng(s, sz) = wrapshift(sz .- s, sz)

# define a new broadcast style
struct CircShiftedArrayStyle{N,S} <: Base.Broadcast.AbstractArrayStyle{N} end

shifts(::Type{CircShiftedArray{T,N,A,S}}) where {T,N,A,S} = S
to_tuple(S::Type{T}) where {T<:Tuple}= tuple(S.parameters...)
"""
    shifts(s::CircShiftedArray)

Return amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(::CircShiftedArray{T,N,A,S}) where {T,N,A,S} = to_tuple(S)

# convenient constructor
CircShiftedArrayStyle{N,S}(::Val{M}, t::Tuple) where {N,S,M} = CircShiftedArrayStyle{max(N,M), Tuple{t...}}()
# make it known to the system
Base.Broadcast.BroadcastStyle(::Type{T}) where (T<: CircShiftedArray) = CircShiftedArrayStyle{ndims(T), shifts(T)}()
# make subarrays (views) of CircShiftedArray also broadcast inthe CircArray style:
Base.Broadcast.BroadcastStyle(::Type{SubArray{T,N,P,I,L}}) where {T,N,P<:CircShiftedArray,I,L} = CircShiftedArrayStyle{ndims(P), shifts(P)}()
# Base.Broadcast.BroadcastStyle(::Type{T}) where (T2,N,P,I,L, T <: SubArray{T2,N,P,I,L})= CircShiftedArrayStyle{ndims(P), shifts(p)}()
Base.Broadcast.BroadcastStyle(::CircShiftedArrayStyle{N,S}, ::Base.Broadcast.DefaultArrayStyle{M}) where {N,S,M} = CircShiftedArrayStyle{max(N,M),S}() #Broadcast.DefaultArrayStyle{CuArray}()
function Base.Broadcast.BroadcastStyle(::CircShiftedArrayStyle{N,S1}, ::CircShiftedArrayStyle{M,S2}) where {N,S1,M,S2}
    if S1 != S2
        # maybe one could force materialization at this point instead.
        error("You currently cannot mix CircShiftedArray of different shifts in a broadcasted expression.")
    end
    CircShiftedArrayStyle{max(N,M),S1}() #Broadcast.DefaultArrayStyle{CuArray}()
end
#Base.Broadcast.BroadcastStyle(::CircShiftedArrayStyle{0,S}, ::Base.Broadcast.DefaultArrayStyle{M}) where {S,M} = CircShiftedArrayStyle{M,S} #Broadcast.DefaultArrayStyle{CuArray}()

@inline Base.size(csa::CircShiftedArray) = size(csa.parent)
@inline Base.size(csa::CircShiftedArray, d::Int) = size(csa.parent, d)
@inline Base.axes(csa::CircShiftedArray) = axes(csa.parent)
@inline Base.IndexStyle(::Type{<:CircShiftedArray}) = IndexLinear()
@inline Base.parent(csa::CircShiftedArray) = csa.parent

CircShiftedVector(v::AbstractVector, s = ()) = CircShiftedArray(v, s)
# CircShiftedVector(v::AbstractVector, s::Number) = CircShiftedArray(v, (s,))
# CircShiftedArray(v::AbstractArray, s::Number) = CircShiftedArray(v, map(mod, padded_tuple(v, s), size(v)))

# linear indexing ignores the shifts
@inline Base.getindex(csa::CircShiftedArray{T,N,A,S}, i::Int) where {T,N,A,S} = getindex(csa.parent, i)
@inline Base.setindex!(csa::CircShiftedArray{T,N,A,S}, v, i::Int) where {T,N,A,S} = setindex!(csa.parent, v, i)

# mod1 avoids first subtracting one and then adding one
@inline Base.getindex(csa::CircShiftedArray{T,N,A,S}, i::Vararg{Int,N}) where {T,N,A,S} = 
    getindex(csa.parent, (mod1(i[j]-to_tuple(S)[j], size(csa.parent, j)) for j in 1:N)...)

@inline Base.setindex!(csa::CircShiftedArray{T,N,A,S}, v, i::Vararg{Int,N}) where {T,N,A,S} = 
    (setindex!(csa.parent, v, (mod1(i[j]-to_tuple(S)[j], size(csa.parent, j)) for j in 1:N)...); v)

# These apply for broadcasted assignment operations.
@inline Base.Broadcast.materialize!(dest::CircShiftedArray{T,N,A,S}, csa::CircShiftedArray{T2,N2,A2,S}) where {T,N,A,S,T2,N2,A2} = Base.Broadcast.materialize!(dest.parent, csa.parent)

# remove all the circ-shift part if all shifts are the same
@inline function Base.Broadcast.materialize!(dest::CircShiftedArray{T,N,A,S}, bc::Base.Broadcast.Broadcasted{CircShiftedArrayStyle{N,S}}) where {T,N,A,S}
    invoke(Base.Broadcast.materialize!, Tuple{A, Base.Broadcast.Broadcasted}, dest.parent, remove_csa_style(bc))
    return dest
end
# we cannot specialize the Broadcast style here, since the rhs may not contain a CircShiftedArray and still wants to be assigned
@inline function Base.Broadcast.materialize!(dest::CircShiftedArray{T,N,A,S}, bc::Base.Broadcast.Broadcasted) where {T,N,A,S}
    #@show "materialize! cs"
    if only_shifted(bc)
        # fall back to standard assignment
        # @show "use raw"
        # to avoid calling the method defined below, we need to use `invoke`:
        invoke(Base.Broadcast.materialize!, Tuple{AbstractArray, Base.Broadcast.Broadcasted}, dest, bc) 
    else
        # get all not-shifted arrays and apply the materialize operations piecewise using array views
        materialize_checkerboard!(dest.parent, bc, Tuple(1:N), wrapshift(size(dest) .- shifts(dest), size(dest)), true)
    end
    return dest
end

@inline function Base.Broadcast.materialize!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{CircShiftedArrayStyle{N,S}}) where {N,S}
    materialize_checkerboard!(dest, bc, Tuple(1:N), wrapshift(size(dest) .- to_tuple(S), size(dest)), false)
    return dest
end

# needs to generate both ranges as both appear in mixed broadcasting expressions
function generate_shift_ranges(dest, myshift)
    circshift_rng_1 = ntuple((d)->firstindex(dest,d):firstindex(dest,d)+myshift[d]-1, ndims(dest))
    circshift_rng_2 = ntuple((d)->firstindex(dest,d)+myshift[d]:lastindex(dest,d), ndims(dest))
    noshift_rng_1 = ntuple((d)->lastindex(dest,d)-myshift[d]+1:lastindex(dest,d), ndims(dest))
    noshift_rng_2 = ntuple((d)->firstindex(dest,d):lastindex(dest,d)-myshift[d], ndims(dest))
    return ((circshift_rng_1, circshift_rng_2), (noshift_rng_1, noshift_rng_2))
end

"""
    materialize_checkerboard!(dest, bc, dims, myshift) 

this function calls itself recursively to subdivide the array into tiles, which each needs to be processed individually via calls to `materialize!`.

|--------|
| a| b   |
|--|-----|---|
| c| dD  | C |
|--+-----|---|
   | B   | A |
   |---------|

"""
function materialize_checkerboard!(dest, bc, dims, myshift, dest_is_cs_array=true) 
    # @show "materialize_checkerboard"
    dest = refine_view(dest)
    # gets Tuples of Tuples of 1D ranges (low and high) for each dimension
    cs_rngs, ns_rngs = generate_shift_ranges(dest, myshift)

    for n in CartesianIndices(ntuple((x)->2, ndims(dest)))
        cs_rng = Tuple(cs_rngs[n[d]][d] for d=1:ndims(dest))
        ns_rng = Tuple(ns_rngs[n[d]][d] for d=1:ndims(dest))
        dst_rng = ifelse(dest_is_cs_array, cs_rng, ns_rng)
        dst_rng = refine_shift_rng(dest, dst_rng)
        dst_view = @view dest[dst_rng...]

        bc1 = split_array_broadcast(bc, ns_rng, cs_rng)
        if (prod(size(dst_view)) > 0)
            Base.Broadcast.materialize!(dst_view, bc1)
        end
    end
end

# some code which determines whether all arrays are shifted
@inline only_shifted(bc::Number)  = true
@inline only_shifted(bc::AbstractArray)  = false
@inline only_shifted(bc::CircShiftedArray)  = true
@inline only_shifted(bc::Base.Broadcast.Broadcasted) = all(only_shifted.(bc.args))

# These functions remove the CircShiftArray in a broadcast and replace each by a view into the original array 
@inline split_array_broadcast(bc::Number, noshift_rng, shift_rng) = bc
@inline split_array_broadcast(bc::AbstractArray, noshift_rng, shift_rng) = @view bc[noshift_rng...]
@inline split_array_broadcast(bc::CircShiftedArray, noshift_rng, shift_rng) = @view bc.parent[shift_rng...]
@inline split_array_broadcast(bc::CircShiftedArray{T,N,A,NTuple{N,0}}, noshift_rng, shift_rng)  where {T,N,A} =  @view bc.parent[noshift_rng...]
@inline function split_array_broadcast(v::SubArray{T,N,P,I,L}, noshift_rng, shift_rng) where {T,N,P<:CircShiftedArray,I,L}    
    new_cs = refine_view(v)
    new_shift_rng = refine_shift_rng(v, shift_rng)
    res = split_array_broadcast(new_cs, noshift_rng, new_shift_rng)
    return res
end

@inline function refine_shift_rng(v::SubArray{T,N,P,I,L}, shift_rng) where {T,N,P,I,L}    
    new_shift_rng = ntuple((d)-> ifelse(isa(v.indices[d],Base.Slice), shift_rng[d], Base.Colon()), ndims(v.parent))
    return new_shift_rng
end
@inline refine_shift_rng(v, shift_rng) = shift_rng

"""
    function refine_view(v::SubArray{T,N,P,I,L}, shift_rng)

returns a refined view of a CircShiftedArray as a CircShiftedArray, if necessary. Otherwise just the original array.
find out, if the range of this view crosses any boundary of the parent CircShiftedArray
by calculating the new indices
if, so though an error. find the full slices, which can stay a circ shifted array withs shifts
"""
function refine_view(v::SubArray{T,N,P,I,L}) where {T,N,P<:CircShiftedArray,I,L}
    myshift = shifts(v.parent)
    sz = size(v.parent)
    # find out, if the range of this view crosses any boundary of the parent CircShiftedArray
    # by calculating the new indices
    # if, so though an error.
    # find the full slices, which can stay a circ shifted array withs shifts
    sub_rngs = ntuple((d)-> !isa(v.indices[d], Base.Slice), ndims(v.parent))

    new_ids_begin = wrapids(ntuple((d)-> v.indices[d][begin] .- myshift[d], ndims(v.parent)), sz)
    new_ids_end = wrapids(ntuple((d)-> v.indices[d][end] .- myshift[d], ndims(v.parent)), sz)
    if any(sub_rngs .&& (new_ids_end .< new_ids_begin))
        error("a view of a shifted array is not allowed to cross boarders of the original array. Do not use a view here.")
        # potentially this can be remedied, once there is a decent CatViews implementation
    end
    new_rngs = ntuple((d)-> ifelse(isa(v.indices[d],Base.Slice), v.indices[d], new_ids_begin[d]:new_ids_end[d]), ndims(v.parent))
    new_shift = ntuple((d)-> ifelse(isa(v.indices[d],Base.Slice), 0, myshift[d]), ndims(v.parent))
    new_cs = CircShiftedArray((@view v.parent.parent[new_rngs...]), new_shift)
    return new_cs
end

refine_view(csa::AbstractArray) = csa

function split_array_broadcast(bc::Base.Broadcast.Broadcasted, noshift_rng, shift_rng)
    # Ref below protects the argument from broadcasting
    bc_modified = split_array_broadcast.(bc.args, Ref(noshift_rng), Ref(shift_rng))
    # @show size(bc_modified[1])
    res=Base.Broadcast.broadcasted(bc.f, bc_modified...)
    # @show typeof(res)
    # Base.Broadcast.Broadcasted{Style, Tuple{modified_axes...}, F, Args}()
    return res
end

Base.Broadcast.materialize!(dest::CircShiftedArray{T,N,A,S}, src::CircShiftedArray) where {T,N,A,S} = Base.Broadcast.materialize!(dest.parent, src.parent)
Base.Broadcast.copyto!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{CircShiftedArrayStyle{N,S}}) where {N,S} = Base.Broadcast.materialize!(dest, bc)

# these array isequal and == functions are defined to be compatible with the previous definition of equality (equal values only)
function Base.isequal(csa::CircShiftedArray{T,N,A,S}, arr::AbstractArray) where {T,N,A,S}
    if isequal(Ref(csa),Ref(arr))
        return true
    end
    all(isequal.(csa,arr))
end
Base.isequal(arr::AbstractArray, csa::CircShiftedArray) = isequal(csa, arr)
Base.isequal(csa1::CircShiftedArray, csa2::CircShiftedArray)  =invoke(isequal, Tuple{CircShiftedArray, AbstractArray}, csa1, csa2)
Base. ==(csa::CircShiftedArray, arr::AbstractArray) = isequal(csa, arr)
Base. ==(arr::AbstractArray, csa::CircShiftedArray) = isequal(csa, arr)
Base. ==(csa1::CircShiftedArray, csa2::CircShiftedArray) = isequal(csa1,csa2)
 
# function copy(CircShiftedArray)
#     collect(CircShiftedArray)
# end
# for speed reasons use the optimized version in Base for actually perfoming the circshift in this case:
Base.collect(csa::CircShiftedArray{T,N,A,S}) where {T,N,A,S} = Base.circshift(csa.parent, to_tuple(S))
# # interaction with numbers should not still stay a CSA
# Base.Broadcast.promote_rule(csa::Type{CircShiftedArray}, na::Type{Number})  = typeof(csa)
# Base.Broadcast.promote_rule(scsa::Type{SubArray{T,N,P,Rngs,B}}, t::T2) where {T,N,P<:CircShiftedArray,Rngs,B,T2}  = typeof(scsa.parent)

# Base.Broadcast.promote_rule(::Type{CircShiftedArray{T,N}}, ::Type{S}) where {T,N,S} = CircShiftedArray{promote_type(T,S),N}
# Base.Broadcast.promote_rule(::Type{CircShiftedArray{T,N}}, ::Type{<:Tuple}, shp...) where {T,N} = CircShiftedArray{T,length(shp)}

# Base.Broadcast.promote_shape(::Type{CircShiftedArray{T,N,A,S}}, ::Type{<:AbstractArray}, ::Type{<:AbstractArray}) where {T,N,A<:AbstractArray,S} = CircShiftedArray{T,N,A,S}
# Base.Broadcast.promote_shape(::Type{CircShiftedArray{T,N,A,S}}, ::Type{<:AbstractArray}, ::Type{<:Number}) where {T,N,A<:AbstractArray,S} = CircShiftedArray{T,N,A,S}

function Base.similar(arr::CircShiftedArray, eltype::Type{T} = eltype(arr), dims::Tuple{Int64, Vararg{Int64, N}} = size(arr)) where {T,N}
    na = similar(arr.parent, eltype, dims)
    # the results-type depends on whether the result size is the same or not.
    return ifelse(size(arr)==dims, na, CircShiftedArray(na, shifts(arr)))
end

@inline remove_csa_style(bc::Base.Broadcast.Broadcasted{CircShiftedArrayStyle{N,S}}) where {N,S} = Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}(bc.f, bc.args, bc.axes) 
@inline remove_csa_style(bc::Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}) where {N} = bc

function Base.similar(bc::Base.Broadcast.Broadcasted{CircShiftedArrayStyle{N,S},Ax,F,Args}, et::ET, dims::Any) where {N,S,ET,Ax,F,Args}
    # remove the CircShiftedArrayStyle from broadcast to call the original "similar" function 
    bc_type = Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N},Ax,F,Args}
    bc_tmp = remove_csa_style(bc) #Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}(bc.f, bc.args, bc.axes)
    res = invoke(Base.Broadcast.similar, Tuple{bc_type,ET,Any}, bc_tmp, et, dims)
    if only_shifted(bc)
        # @show "only shifted"
        return CircShiftedArray(res, to_tuple(S))
    else
        return res
    end
end

function Base.show(io::IO, mm::MIME"text/plain", cs::CircShiftedArray) 
    # using CUDA
    # CUDA.@allowscalar invoke(Base.show, Tuple{IO, typeof(mm), AbstractArray}, io, mm, cs) 
    invoke(Base.show, Tuple{IO, typeof(mm), AbstractArray}, io, mm, cs) 
end

