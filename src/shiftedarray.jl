export ShiftedArray, CircShift
using Base

# just a type to indicate that this is a ShiftedArray rather than the ShiftedArray 
struct CircShift end
# function CSA_Type(T1::TypeVar, T2::TypeVar)
#     @show T2.name
#     return ifelse(T2.name == :CircShift, T1, Union{T1, T2})
# end
# CSA_Type(T::TypeVar, ::Type{CircShift}) = T
#CSA_Type(::Type{T1},::Type{T2}) where {T1,T2} = Union{T1,T2}
# to ensure that eltype(CircShiftedArray) is not a Union type.
#CSA_Type(::Type{T},::CircShift) where {T} = Type{T}


"""
    ShiftedArray(parent::AbstractArray, shifts, default)

Custom `AbstractArray` object to store an `AbstractArray` `parent` shifted by `shifts` steps
(where `shifts` is a `Tuple` with one `shift` value per dimension of `parent`).
For `s::ShiftedArray`, `s[i...] == s.parent[map(-, i, s.shifts)...]` if `map(-, i, s.shifts)`
is a valid index for `s.parent`, and `s.v[i, ...] == default` otherwise.
Use `copy` to collect the values of a `ShiftedArray` into a normal `Array`.
The recommended constructor is `ShiftedArray(parent, shifts; default = missing)`.

!!! note
    If `parent` is itself a `ShiftedArray` with a compatible default value,
    the constructor does not nest `ShiftedArray` objects but rather combines
    the shifts additively.

# Examples

```jldoctest shiftedarray
julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedVector{Int64, Missing, Vector{Int64}}:
  missing
 1
 3
 5

julia> v = [1, 3, 5, 4];

julia> s = ShiftedArray(v, (1,))
4-element ShiftedVector{Int64, Missing, Vector{Int64}}:
  missing
 1
 3
 5

julia> copy(s)
4-element Vector{Union{Missing, Int64}}:
  missing
 1
 3
 5

julia> v = reshape(1:16, 4, 4);

julia> s = ShiftedArray(v, (0, 2))
4×4 ShiftedArray{Int64, Missing, 2, Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}}:
 missing  missing  1  5
 missing  missing  2  6
 missing  missing  3  7
 missing  missing  4  8

julia> shifts(s)
(0, 2)
```
"""
struct ShiftedArray{T, N, A<:AbstractArray{T,N}, myshift<:Tuple, R} <: AbstractArray{Union{T,R}, N} #
    parent::A

    function ShiftedArray(p::AbstractArray{T,N}, n=(); default=missing)::ShiftedArray{T,N,typeof(p), Tuple, R} where {T,N}
        myshifts = padded_tuple(p, n)
        return new{T,N,typeof(p), Tuple{myshifts...}, to_default_type(default)}(p)
    end
    # if a ShiftedArray is wrapped in a ShiftedArray, only a single CSA results ONLY if the default does not change! 
    function ShiftedArray(p::ShiftedArray{T,N,A,S,R}, n=(); default=default(p))::ShiftedArray{T,N,A,Tuple, R} where {T,N,A,S,R}
        myshifts = padded_tuple(p, n)
        if isa(default,R)
            return new{T,N,A, Tuple{(myshifts.+ to_tuple(shifts(typeof(p))))...}, to_default_type(default)}(p.parent)
        else
            return new{eltype(p),N,typeof(p), Tuple{myshifts...}, to_default_type(default)}(p)
        end
    end
    # if default changed, we need to create a double-wrapped array
    # function ShiftedArray(p::ShiftedArray{T,N,A,S,R}, n=(); default=missing) where {T,N,A,S,R}
    #     @show R
    #     @show "c3"
    #     myshifts = padded_tuple(p, n)
    #     return new{eltype(p),N,typeof(p), Tuple{myshifts...}, to_default_type(default)}(p)
    # end
    # function ShiftedArray(p::AbstractArray{T,N}, n=(), R=undef)::ShiftedArray{T,N,typeof(p), Tuple, R} where {T,N}
    #     myshifts = map(mod, padded_tuple(p, n), size(p))
    #     ws::NTuple{N,Int} = wrapshift(myshifts, size(p))
    #     return new{T,N,typeof(p), Tuple{ws...}, CircShift}(p)
    # end
    # # if a ShiftedArray is wrapped in a ShiftedArray, only a single CSA results 
    # function ShiftedArray(p::ShiftedArray{T,N,A,S}, n=())::ShiftedArray{T,N,A,Tuple, R} where {T,N,A,S}
    #     myshifts = map(mod, padded_tuple(p, n), size(p))
    #     ws::NTuple{N,Int} = wrapshift(myshifts .+ to_tuple(shifts(typeof(p))), size(p))
    #     return new{T,N,A, Tuple{ws...}, CircShift}(p.parent)
    # end
end

to_default_type(default::Val)=typeof(default)
to_default_type(default::Type)=default
to_default_type(default::Missing) = Missing
to_default_type(default::Nothing) = Nothing
to_default_type(default::CircShift) = CircShift
to_default_type(default)=typeof(Val(default))


"""
    default(s::ShiftedArray)

Return default value.
"""
default(s::ShiftedArray{T,N,A,S,R}) where {T,N,A,S,R} = default(R)
default(::AbstractArray) = missing

function default(R1,R2)
    if R1 != R2
        error("propagating multiple arrays in one expression which contains only shifted arrays all need the same default.")
    end
    R1
end
# default(Datatype) should NOT be called.
# default(::Type{T}) where T = T
default(::Missing) = missing
default(::Type{Missing}) = missing
default(::Nothing) = nothing
default(::Type{Nothing}) = nothing
default(::Type{Val{N}}) where N = N
# default(::T) where T = T
default(::Type{ShiftedArray{T,N,A,S,R}}) where {T,N,A,S,R} = default(R)
default(R::Type{CircShift}) = CircShift
default(R1, R2::Type{CircShift}) = R1()
default(R1::Type{CircShift}, R2) = R2()
default(R1::Type{CircShift}, R2::Type{CircShift}) = CircShift

# low-level private constructor to handle type parameters
function shiftedarray(v::AbstractArray{T, N}, shifts, r=default(v)()) where {T, N}
    return ShiftedArray(v, padded_tuple(v, shifts); default=r)
end

"""
    padded_tuple(v::AbstractVector, s)

Internal function used to compute shifts. Return a `Tuple` with as many element
as the dimensions of `v`. The first `length(s)` entries are filled with values
from `s`, the remaining entries are `0`. `s` should be an integer, in which case
`length(s) == 1`, or a container of integers with keys `1:length(s)`.

# Examples

```jldoctest padded_tuple
julia> ShiftedArrays.padded_tuple(rand(10, 10), 3)
(3, 0)

julia> ShiftedArrays.padded_tuple(rand(10, 10), (4,))
(4, 0)

julia> ShiftedArrays.padded_tuple(rand(10, 10), (1, 5))
(1, 5)
```
"""
padded_tuple(v::AbstractArray, s) = ntuple(i -> i ≤ length(s) ? s[i] : 0, ndims(v))

"""
    shifts(s::ShiftedArray)

Return amount by which `s` is shifted compared to `parent(s)`.
"""
shifts(::ShiftedArray{T,N,A,S,R}) where {T,N,A,S,R} = to_tuple(S)

to_tuple(S::Type{T}) where {T<:Tuple}= tuple(S.parameters...)
shifts(::Type{ShiftedArray{T,N,A,S,R}}) where {T,N,A,S,R} = S


"""
    ShiftedVector{T, S<:AbstractArray}

Shorthand for `ShiftedArray{T, 1, A, S, M}`.
"""
const ShiftedVector{T, N, A<:AbstractArray, S, M} = ShiftedArray{T, 1, A, S, M}

function ShiftedVector(v::AbstractVector, n = (); default = ShiftedArrays.default(v))
    return ShiftedArray(v, n; default = default)
end

# Computing a shifted index (subtracting the offset)
offset(offsets::NTuple{N,Int}, inds::NTuple{N,Int}) where {N} = map(-, inds, offsets)

# we keep this for compatability reasons
@inline function bringwithin(ind_with_offset::Int, ranges::AbstractUnitRange)
    return ifelse(ind_with_offset < first(ranges), ind_with_offset + length(ranges), ind_with_offset)
end

# wraps shifts into the range 0...N-1
wrapshift(shift::NTuple, dims::NTuple) = ntuple(i -> mod(shift[i], dims[i]), length(dims))
# wraps indices into the range 1...N
wrapids(shift::NTuple, dims::NTuple) = ntuple(i -> mod1(shift[i], dims[i]), length(dims))
invert_rng(s, sz) = wrapshift(sz .- s, sz)

# define a new broadcast style. Stores dimensions (N), Shift(S) and default type (R)
struct ShiftedArrayStyle{N,S,R} <: Base.Broadcast.AbstractArrayStyle{N} end

# convenient constructor
ShiftedArrayStyle{N,S,R}(::Val{M}, t::Tuple) where {N,S,M,R} = ShiftedArrayStyle{max(N,M), Tuple{t...},R}()
# make it known to the system
function Base.Broadcast.BroadcastStyle(::Type{T}) where (T<: ShiftedArray)
     ShiftedArrayStyle{ndims(T), shifts(T), to_default_type(default(T))}()
end
# make subarrays (views) of ShiftedArray also broadcast inthe ShiftedArray style:
Base.Broadcast.BroadcastStyle(::Type{SubArray{T,N,P,I,L}}) where {T,N,P<:ShiftedArray,I,L} = ShiftedArrayStyle{ndims(P), shifts(P), to_default_type(default(P))}()
# Base.Broadcast.BroadcastStyle(::Type{T}) where (T2,N,P,I,L, T <: SubArray{T2,N,P,I,L})= ShiftedArrayStyle{ndims(P), shifts(p), to_default_type(default(p))}()
# ShiftedArray and default Array broadcast to ShiftedArray with max dimensions between the two
Base.Broadcast.BroadcastStyle(::ShiftedArrayStyle{N,S,R}, ::Base.Broadcast.DefaultArrayStyle{M}) where {N,S,M,R} = ShiftedArrayStyle{max(N,M),S,R}() #Broadcast.DefaultArrayStyle{CuArray}()
function Base.Broadcast.BroadcastStyle(::ShiftedArrayStyle{N,S1,R1}, ::ShiftedArrayStyle{M,S2,R2}) where {N,S1,R1,M,S2,R2}
    if S1 != S2
        # maybe one could force materialization at this point instead.
        error("You currently cannot mix ShiftedArray of different shifts in a broadcasted expression.")
    end
    # Note that there are separate propagation rules for the default (everything wins over CircShift)
    ShiftedArrayStyle{max(N,M),S1, default(R1,R2)}() #Broadcast.DefaultArrayStyle{CuArray}()
end 
#Base.Broadcast.BroadcastStyle(::ShiftedArrayStyle{0,S},R, ::Base.Broadcast.DefaultArrayStyle{M}) where {S,M,R} = ShiftedArrayStyle{M,S,R} #Broadcast.DefaultArrayStyle{CuArray}()

@inline Base.size(csa::ShiftedArray) = size(csa.parent)
@inline Base.size(csa::ShiftedArray, d::Int) = size(csa.parent, d)
@inline Base.axes(csa::ShiftedArray) = axes(csa.parent)
@inline Base.IndexStyle(::Type{<:ShiftedArray}) = IndexLinear()
@inline Base.parent(csa::ShiftedArray) = csa.parent


@inline function Base.getindex(s::ShiftedArray{<:Any, N, <:Any, <:Any, <:Any}, x::Vararg{Int, N}) where {N}
    # @show "gi shifted"
    @boundscheck checkbounds(s, x...)
    v, i = parent(s), offset(shifts(s), x)
    return if checkbounds(Bool, v, i...)
        @inbounds v[i...]
    else
        default(s)
    end
end

# linear indexing ignores the shifts
@inline function Base.getindex(csa::ShiftedArray{T,N,A,S,R}, i::Int) where {T,N,A,S,R} 
    # @show "gi 0"
    getindex(csa.parent, i)
end

@inline function Base.setindex!(csa::ShiftedArray{T,N,A,S,R}, v, i::Vararg{Int,N}) where {T,N,A,S,R}
    # @show "si 1"
    # note that we simply use the cyclic method, since the missing values are simply ignored
    setindex!(csa.parent, v, (mod1(i[j]-to_tuple(S)[j], size(csa.parent, j)) for j in 1:N)...)
    csa
end

# setting a value which corresponds to the border type is ignored
@inline function Base.setindex!(csa::ShiftedArray{T,N,A,S,R}, v::R, i::Vararg{Int,N}) where {T,N,A,S,R}
    #@show "si 2"
    csa
end

# These apply for broadcasted assignment operations, if the shifts are identical
# @inline Base.Broadcast.materialize!(dest::ShiftedArray{T,N,A,S,R1}, csa::ShiftedArray{T2,N2,A2,S,R2}) where {T,N,A,S,T2,N2,A2,R1,R2} = Base.Broadcast.materialize!(dest.parent, csa.parent)
@inline function Base.Broadcast.materialize!(dest::ShiftedArray{T,N,A,S,R}, src::ShiftedArray) where {T,N,A,S,R} 
    #@show "bc3"
    if shifts(dest) != shifts(src)
        error("Copyiing into a ShiftedArray of different shift is disallowed. Use the same shift or an ordinary array.")
    end
    Base.Broadcast.materialize!(dest.parent, src.parent)
end

function Base.Broadcast.copyto!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N,S,R}}) where {N,S,R}
    # @show "copyto!"
     Base.Broadcast.materialize!(dest, bc)
end
# remove all the (circ-)shift part if all shifts are the same (or constants)
# @inline function materialize!(dest::ShiftedArray{T, N, A, S, R}, bc::Base.Broadcast.Broadcasted{ShiftedArrays.ShiftedArrayStyle{N, S, R}}) where {T, N, A, S, R, N, S, R}
@inline function Base.Broadcast.materialize!(dest::ShiftedArray{T, N, A, S, R}, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N, S, R}}) where {T, N, A, S, R}
    # @show "materialize! cs1"
    # @show remove_sa_style(bc)
    #@show A
    invoke(Base.Broadcast.materialize!, Tuple{A, Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}}, dest.parent, remove_sa_broadcast(bc))
    # Base.Broadcast.materialize!(dest, remove_sa_style(bc))
    return dest
end

# we cannot specialize the Broadcast style here, since the rhs may not contain a ShiftedArray and still wants to be assigned
@inline function Base.Broadcast.materialize!(dest::ShiftedArray{T,N,A,S,R}, bc::Base.Broadcast.Broadcasted{BT}) where {T,N,A,S,R,BT}
    # @show "materialize! cs2"
    if only_shifted(bc)
        # fall back to standard assignment
        #@show "use raw"
        # to avoid calling the method defined below, we need to use `invoke`:
        invoke(Base.Broadcast.materialize!, Tuple{AbstractArray, Base.Broadcast.Broadcasted}, dest, bc) 
    else
        # get all not-shifted arrays and apply the materialize operations piecewise using array views
        materialize_checkerboard!(dest.parent, bc, Tuple(1:N), shifts(dest), true)
    end
    return dest
end

# for ambiguous conflict resolution
# @inline function Base.Broadcast.materialize!(dest::ShiftedArray{T,N,A,S,R}, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N2,S,R}}) where {T,N,A,S,R,N2}
#     @show "materialize! cs4"
#     if only_shifted(bc)
#         # fall back to standard assignment
#         #@show "use raw"
#         # to avoid calling the method defined below, we need to use `invoke`:
#         invoke(Base.Broadcast.materialize!, Tuple{AbstractArray, Base.Broadcast.Broadcasted}, dest, bc) 
#     else
#         # get all not-shifted arrays and apply the materialize operations piecewise using array views
#         materialize_checkerboard!(dest.parent, bc, Tuple(1:N), wrapshift(size(dest) .- shifts(dest), size(dest)), true)
#     end
#     return dest
# end

@inline function Base.Broadcast.materialize!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N,S,R}}) where {N,S,R}
    materialize_checkerboard!(dest, bc, Tuple(1:N), to_tuple(S), false)
    return dest
end

# This collect function needs to be defined to prevent the linear indexing to take over and just copy the raw (not shifted) data.
function Base.collect(src::ShiftedArray{T,N,A,S,R}) where {T,N,A,S,R}
    # @show "collect"
    src = if (isa(src.parent,ShiftedArray))
        ShiftedArray(collect(src.parent), shifts(src); default=default(src))
    else
        src
    end
    bc = Base.Broadcast.broadcasted(identity, src)
    dest = similar(src.parent, eltype(src))
    materialize_checkerboard!(dest, bc, Tuple(1:N), to_tuple(S), false; array_type=R)
    return dest
end

# needs to generate both ranges as both appear in mixed broadcasting expressions
function generate_shift_ranges(dest, myshift)
    shift_rng_1 = ntuple((d)->firstindex(dest,d):firstindex(dest,d)+myshift[d]-1, ndims(dest))
    shift_rng_2 = ntuple((d)->firstindex(dest,d)+myshift[d]:lastindex(dest,d), ndims(dest))
    noshift_rng_1 = ntuple((d)->lastindex(dest,d)-myshift[d]+1:lastindex(dest,d), ndims(dest))
    noshift_rng_2 = ntuple((d)->firstindex(dest,d):lastindex(dest,d)-myshift[d], ndims(dest))
    return ((shift_rng_1, shift_rng_2), (noshift_rng_1, noshift_rng_2))
end

"""
    materialize_checkerboard!(dest, bc, dims, myshift) 

this function subdivides the array into tiles, which each needs to be processed individually via calls to `materialize!`.

|--------|
| a| b   |
|--|-----|---|
| c| dD  | C |
|--+-----|---|
   | B   | A |
   |---------|

"""
function materialize_checkerboard!(dest, bc, dims, myshift, dest_is_cs_array=true; array_type=CircShift) 
    #@show "materialize_checkerboard"
    dest = refine_view(dest)
    # gets Tuples of Tuples of 1D ranges (low and high) for each dimension
    cs_rngs, ns_rngs = generate_shift_ranges(dest, wrapshift(size(dest) .- myshift, size(dest)))

    # @show cs_rngs
    # @show ns_rngs
    # @show nonflipped_source(myshift)
    #N = 1
    nonflipped = nonflipped_source(myshift)
    for n in CartesianIndices(ntuple((x)->2, ndims(dest)))
        cs_rng = Tuple(cs_rngs[n[d]][d] for d=1:ndims(dest))
        ns_rng = Tuple(ns_rngs[n[d]][d] for d=1:ndims(dest))
        dst_rng = ifelse(dest_is_cs_array, cs_rng, ns_rng)
        dst_rng = refine_shift_rng(dest, dst_rng)
        dst_view = @view dest[dst_rng...]

        bc1 = split_array_broadcast(bc, ns_rng, cs_rng)
        if (prod(size(dst_view)) > 0)
            if (array_type <: CircShift || Tuple(n) == nonflipped)
                Base.Broadcast.materialize!(dst_view, bc1)
            else
                dst_view .= default(array_type)
            end
        end
        # dst_view .= N
        # N=N+1
    end
end

# identifies which quadrant corresponds to the original (non-flipped quadrant)
function nonflipped_source(myshift)
    (myshift.<=0) .+ 1
end

# some code which determines whether all arrays are shifted
@inline only_shifted(bc::Number)  = true
@inline only_shifted(bc::AbstractArray)  = false
@inline only_shifted(bc::ShiftedArray)  = true
@inline only_shifted(bc::Base.Broadcast.Broadcasted) = all(only_shifted.(bc.args))
@inline only_shifted(bc::Base.Broadcast.Extruded) = only_shifted(bc.x)

# These functions remove the ShiftArray in a broadcast and replace each by a view into the original array 
@inline split_array_broadcast(bc::Number, noshift_rng, shift_rng) = bc
@inline split_array_broadcast(bc::AbstractArray, noshift_rng, shift_rng) = @view bc[noshift_rng...]
@inline split_array_broadcast(bc::ShiftedArray, noshift_rng, shift_rng) = @view bc.parent[shift_rng...]
@inline split_array_broadcast(bc::ShiftedArray{T,N,A,NTuple{N,0},R}, noshift_rng, shift_rng)  where {T,N,A,R} =  @view bc.parent[noshift_rng...]
@inline function split_array_broadcast(v::SubArray{T,N,P,I,L}, noshift_rng, shift_rng) where {T,N,P<:ShiftedArray,I,L}    
    new_cs = refine_view(v)
    new_shift_rng = refine_shift_rng(v, shift_rng)
    res = split_array_broadcast(new_cs, noshift_rng, new_shift_rng)
    return res
end

function split_array_broadcast(bc::Base.Broadcast.Broadcasted, noshift_rng, shift_rng)
    # Ref below protects the argument from broadcasting
    bc_modified = split_array_broadcast.(bc.args, Ref(noshift_rng), Ref(shift_rng))
    # @show size(bc_modified[1])
    res = Base.Broadcast.broadcasted(bc.f, bc_modified...)
    # @show typeof(res)
    # Base.Broadcast.Broadcasted{Style, Tuple{modified_axes...}, F, Args}()
    return res
end

# These function remove the ShiftedArray properties from the Broadcast chain
@inline remove_sa_broadcast(bc::Number) = bc
@inline remove_sa_broadcast(bc::AbstractArray) = bc
@inline remove_sa_broadcast(bc::ShiftedArray) = bc.parent
function remove_sa_broadcast(bc::Base.Broadcast.Broadcasted)
    # Ref below protects the argument from broadcasting
    bc_modified = remove_sa_broadcast.(bc.args)
    res = Base.Broadcast.broadcasted(bc.f, bc_modified...)
    # @show typeof(res)
    # Base.Broadcast.Broadcasted{Style, Tuple{modified_axes...}, F, Args}()
    return res
end

@inline function refine_shift_rng(v::SubArray{T,N,P,I,L}, shift_rng) where {T,N,P,I,L}    
    new_shift_rng = ntuple((d)-> ifelse(isa(v.indices[d], Base.Slice), shift_rng[d], Base.Colon()), ndims(v.parent))
    return new_shift_rng
end
@inline refine_shift_rng(v, shift_rng) = shift_rng

"""
    function refine_view(v::SubArray{T,N,P,I,L}, shift_rng)

returns a refined view of a SubArray of a ShiftedArray as a ShiftedArray, if necessary. Otherwise just the original array.
find out, if the range of this view crosses any boundary of the parent ShiftedArray
by calculating the new indices
if, so though an error. find the full slices, which can stay a (circ-)shifted array withs shifts
"""
function refine_view(v::SubArray{T,N,P,I,L}) where {T,N,P<:ShiftedArray,I,L}
    myshift = shifts(v.parent)
    sz = size(v.parent)
    # find out, if the range of this view crosses any boundary of the parent ShiftedArray
    # by calculating the new indices
    # if, so though an error.
    # find the full slices, which can stay a circ shifted array withs shifts
    sub_rngs = ntuple((d)-> !isa(v.indices[d], Base.Slice), ndims(v.parent))

    # in the line below one should better use "begin" instead of "1" but this is not supported by early Julia versions.
    new_ids_begin = wrapids(ntuple((d)-> v.indices[d][1] .- myshift[d], ndims(v.parent)), sz)
    new_ids_end = wrapids(ntuple((d)-> v.indices[d][end] .- myshift[d], ndims(v.parent)), sz)
    if any(sub_rngs .& (new_ids_end .< new_ids_begin))
        error("a view of a shifted array is not allowed to cross boarders of the original array. Do not use a view here.")
        # potentially this can be remedied, once there is a decent CatViews implementation
    end
    new_rngs = ntuple((d)-> ifelse(isa(v.indices[d],Base.Slice), v.indices[d], new_ids_begin[d]:new_ids_end[d]), ndims(v.parent))
    new_shift = ntuple((d)-> ifelse(isa(v.indices[d],Base.Slice), 0, myshift[d]), ndims(v.parent))
    new_cs = ShiftedArray((@view v.parent.parent[new_rngs...]), new_shift)
    return new_cs
end

refine_view(csa::AbstractArray) = csa

# these array isequal and == functions are defined to be compatible with the previous definition of equality (equal values only)
function Base.isequal(csa::ShiftedArray{T,N,A,S,R}, arr::AbstractArray) where {T,N,A,S,R}
    # @show "is equal"
    if isequal(Ref(csa), Ref(arr))
        return true
    end
    res = all(isequal.(csa, arr))
    return ifelse(ismissing(res), true, res)
end

Base.isequal(arr::AbstractArray, csa::ShiftedArray) = isequal(csa, arr)
Base.isequal(csa1::ShiftedArray, csa2::ShiftedArray)  = invoke(isequal, Tuple{ShiftedArray, AbstractArray}, csa1, csa2)
Base. ==(csa::ShiftedArray, arr::AbstractArray) = isequal(csa, arr)
Base. ==(arr::AbstractArray, csa::ShiftedArray) = isequal(csa, arr)
Base. ==(csa1::ShiftedArray, csa2::ShiftedArray) = isequal(csa1,csa2)

function Base.copy(arr::ShiftedArray)
    collect(arr)
end

Base.eltype(arr::ShiftedArray{T,N,A,S,R})  where {T,N,A,S,R<:CircShift} = eltype(parent(arr))

# broadcasted(::coalesce, a::ShiftedArray, b) = broadcasted((a, b) -> a && b, a, b)

# # interaction with numbers should not still stay a CSA
# Base.Broadcast.promote_rule(csa::Type{ShiftedArray}, na::Type{Number})  = typeof(csa)
# Base.Broadcast.promote_rule(scsa::Type{SubArray{T,N,P,Rngs,B}}, t::T2) where {T,N,P<:ShiftedArray,Rngs,B,T2}  = typeof(scsa.parent)

# Base.Broadcast.promote_rule(::Type{ShiftedArray{T,N}}, ::Type{S}) where {T,N,S} = ShiftedArray{promote_type(T,S),N}
# Base.Broadcast.promote_rule(::Type{ShiftedArray{T,N}}, ::Type{<:Tuple}, shp...) where {T,N} = ShiftedArray{T,length(shp)}

# Base.Broadcast.promote_shape(::Type{ShiftedArray{T,N,A,S}}, ::Type{<:AbstractArray}, ::Type{<:AbstractArray}) where {T,N,A<:AbstractArray,S} = ShiftedArray{T,N,A,S}
# Base.Broadcast.promote_shape(::Type{ShiftedArray{T,N,A,S}}, ::Type{<:AbstractArray}, ::Type{<:Number}) where {T,N,A<:AbstractArray,S} = ShiftedArray{T,N,A,S}

function Base.similar(arr::ShiftedArray, eltp::Type{T} = eltype(arr), dims::Tuple{Int64, Vararg{Int64, N}} = size(arr)) where {T,N}
    # @show "similar 1"
    na = similar(arr.parent, eltp, dims)
    # the results-type depends on whether the result size is the same or not. Same size can remain ShiftedArray.
    # its important that a shifted array is the result for reductions on CircShiftedArray, since only then the broadcasting works
    # Since similar cannot infer the shift information when a sub-range ws created e.g. sv[1:3] 
    return na # ifelse(size(arr)==dims, na, ShiftedArray(na, shifts(arr); default=default(arr)))
end

# specialized version for CircShiftArray which removes the Union Type
function Base.similar(arr::ShiftedArray, eltp::Type{Union{CircShift,T}} = eltype(arr), dims::Tuple{Int64, Vararg{Int64, N}} = size(arr)) where {T,N}
    # @show "similar 1B"
    na = similar(arr.parent, T, dims)
    return na 
end

# This one is called for reduce operations to allocate like similar
function Base.reducedim_initarray(arr::ShiftedArray, region, init, r::Type{R}) where R
    # @show "reducedim"
    # @show region
    # @show init
    res = invoke(Base.reducedim_initarray, Tuple{AbstractArray, typeof(region), typeof(init), typeof(r)}, arr, region,init,r)
    return ShiftedArray(res, shifts(arr), default=default(arr))
end

@inline remove_sa_style(bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N,S,R}}) where {N,S,R} = Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}(bc.f, bc.args, bc.axes) 
@inline remove_sa_style(bc::Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}) where {N} = bc

function Base.similar(bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N,S,R},Ax,F,Args}, et::ET, dims::Any) where {N,S,R,ET,Ax,F,Args}
    #@show "similar 2"
    # remove the ShiftedArrayStyle from broadcast to call the original "similar" function 
    bc_type = Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N},Ax,F,Args}
    bc_tmp = remove_sa_style(bc) #Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}(bc.f, bc.args, bc.axes)
    res = invoke(Base.Broadcast.similar, Tuple{bc_type,ET,Any}, bc_tmp, et, dims)
    # if all broadcast members are shifted, also return a shifted version
    if only_shifted(bc)
        #@show "only shifted"
        # return a ShiftedArray. This makes operations much faster since linear indexing can be used
        # @show default(R)
        return ShiftedArray(res, to_tuple(S); default=default(R))
    else
        return res
    end
end

function Base.show(io::IO, mm::MIME"text/plain", cs::ShiftedArray) 
    # a bit of a hack to determine whether the datatype is CuArray without needing a CUDA.jl dependence
    if startswith(string(typeof(cs.parent)),"CuArray")
        # this is needed such that the show method does not throw an error when individual element access is used
        buffer = IOBuffer()
        ioc = IOContext(buffer, io)
        #invoke(Base.show, Tuple{IO, typeof(mm), typeof(cs.parent)}, ioc, mm, cs.parent) 
        # unfortunately we have to collect here
        show(ioc, mm, collect(cs))
        buffer = String(take!(buffer))
        lines = split(buffer,"\n")
        lines[1] = string(typeof(cs)) * ":"
        print(io, join(lines,"\n"))
        # @allowscalar invoke(Base.show, Tuple{IO, typeof(mm), AbstractArray}, io, mm, cs) 
    else
        invoke(Base.show, Tuple{IO, typeof(mm), AbstractArray}, io, mm, cs) 
    end
end

