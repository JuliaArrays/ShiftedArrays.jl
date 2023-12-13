using Base
using Core.Compiler

# just a type to indicate that this is a ShiftedArray rather than the ShiftedArray 
struct CircShift end

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
4-element ShiftedVector{Union{Missing, Int64}, Vector{Int64}, Missing}:
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
4×4 ShiftedArray{Union{Missing, Int64}, 2, Base.ReshapedArray{Int64, 2, UnitRange{Int64}, Tuple{}}, Missing}:
 missing  missing  1  5
 missing  missing  2  6
 missing  missing  3  7
 missing  missing  4  8

julia> shifts(s)
(0, 2)
```
"""
struct ShiftedArray{T, N, A<:AbstractArray, R} <: AbstractArray{T, N} 
    parent::A
    shifts::NTuple{N, Int}

    function ShiftedArray(p::AbstractArray{Tb,N}, n=(); default=missing) where {Tb,N}
        return new{shifted_array_base_type(Tb, default), N, typeof(p), to_default_type(default)}(p, padded_tuple(p, n))
    end
    # if a ShiftedArray is wrapped in a ShiftedArray, only a single CSA results ONLY if the default does not change! 
    function ShiftedArray(p::ShiftedArray{Tb,N,A,R}, n=(); default=default(p)) where {Tb,N,A,R}
        myshifts = padded_tuple(p, n)
        if isa(default,R)
            return new{shifted_array_base_type(Tb, default),N,A, to_default_type(default)}(p.parent, myshifts.+ shifts(p))
        else
            return new{eltype(p),N,typeof(p), to_default_type(default)}(p, myshifts)
        end

    end
end

shifted_array_base_type(::Type{T}, default::R) where {T,R} = Union{T,R}
shifted_array_base_type(::Type{T}, default::CircShift) where {T} = T

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
default(s::ShiftedArray{T,N,A,R}) where {T,N,A,R} = default(R)
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
default(::Type{ShiftedArray{T,N,A,R}}) where {T,N,A,R} = default(R)
default(R::Type{CircShift}) = CircShift()
default(R1, R2::Type{CircShift}) = R1()
default(R1::Type{CircShift}, R2) = R2()
default(R1::Type{CircShift}, R2::Type{CircShift}) = CircShift()
# default applied to a Broadcast calculates the default value
function default(bc::Base.Broadcast.Broadcasted)
    bcd = replace_by_default_broadcast(bc)
    #@show bcd
    dv = collect(bcd)
    #@show dv
    if prod(size(dv)) != 1
        error("wrong size of dv")
    end
    return dv[1]
end

# find out, whether any of the arguments is a circ-shifted array
has_circ_type(a) = false
has_circ_type(bc::Base.Broadcast.Broadcasted) = any(has_circ_type.(bc.args))

# low-level private constructor to handle type parameters
function shiftedarray(v::AbstractArray{T, N}, shifts, r=default(v)) where {T, N}
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
@inline shifts(arr::ShiftedArray{T,N,A,R}) where {T,N,A,R} = arr.shifts

# to_tuple(S::Type{T}) where {T<:Tuple}= tuple(S.parameters...)
# shifts(arr::Type{ShiftedArray}) = arr.shifts


"""
    ShiftedVector{T, S<:AbstractArray}

Shorthand for `ShiftedArray{T, 1, A, M}`.
"""
const ShiftedVector{T, N, A<:AbstractArray, M} = ShiftedArray{T, 1, A, M}

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
struct ShiftedArrayStyle{N} <: Base.Broadcast.AbstractArrayStyle{N} end

# convenient constructor
ShiftedArrayStyle{N}(::Val{M}) where {N,M} = ShiftedArrayStyle{max(N,M)}()

# make it known to the system
function Base.Broadcast.BroadcastStyle(::Type{T}) where (T<: ShiftedArray)
    #@show "Style SA"
    #@show shifts(T)
     ShiftedArrayStyle{ndims(T)}()
end

# make subarrays (views) of ShiftedArray also broadcast inthe ShiftedArray style:
Base.Broadcast.BroadcastStyle(::Type{SubArray{T,N,P,I,L}}) where {T,N,P<:ShiftedArray,I,L} = ShiftedArrayStyle{ndims(P)}()
# ShiftedArray and default Array broadcast to ShiftedArray with max dimensions between the two
Base.Broadcast.BroadcastStyle(::ShiftedArrayStyle{N}, ::Base.Broadcast.DefaultArrayStyle{M}) where {N,M} = ShiftedArrayStyle{max(N,M)}() 
Base.Broadcast.BroadcastStyle(::Base.Broadcast.DefaultArrayStyle{M}, ::ShiftedArrayStyle{N}) where {M,N} = ShiftedArrayStyle{max(N,M)}() 
Base.Broadcast.BroadcastStyle(::ShiftedArrayStyle{N}, ::Base.Broadcast.AbstractArrayStyle{M}) where {N,M} = ShiftedArrayStyle{max(N,M)}() 
Base.Broadcast.BroadcastStyle(::Base.Broadcast.AbstractArrayStyle{M}, ::ShiftedArrayStyle{N}) where {M,N} = ShiftedArrayStyle{max(N,M)}() 

@inline Base.size(csa::ShiftedArray) = size(csa.parent)
@inline Base.size(csa::ShiftedArray, d::Int) = size(csa.parent, d)
@inline Base.axes(csa::ShiftedArray) = axes(csa.parent)
@inline Base.IndexStyle(::Type{<:ShiftedArray}) = IndexLinear()
@inline Base.parent(csa::ShiftedArray) = csa.parent

@inline function Base.getindex(s::ShiftedArray{<:Any, N, <:Any, <:Any}, x::Vararg{Int, N}) where {N}
    #@show "gi shifted"
    @boundscheck checkbounds(s, x...)
    v, i = parent(s), offset(shifts(s), x)
    return if checkbounds(Bool, v, i...)
        @inbounds v[i...]
    else
        default(s)
    end
end

# linear indexing ignores the shifts
@inline function Base.getindex(csa::ShiftedArray{T,N,A,R}, i::Int) where {T,N,A,R} 
    getindex(csa.parent, i)
end

@inline function Base.setindex!(csa::ShiftedArray{T,N,A,R}, v, i::Int) where {T,N,A,R}
    # note that we simply use the cyclic method, since the missing values are simply ignored
    setindex!(csa.parent, v, i)
end

@inline function Base.setindex!(csa::ShiftedArray{T,N,A,R}, v, i::Vararg{Int,N}) where {T,N,A,R}
    # note that we simply use the cyclic method, since the missing values are simply ignored
    setindex!(csa.parent, v, (mod1(i[j]-shifts(csa)[j], size(csa.parent, j)) for j in 1:N)...)
    csa
end

# setting a value which corresponds to the border type is ignored
@inline function Base.setindex!(csa::ShiftedArray{T,N,A,R}, v::R, i::Vararg{Int,N}) where {T,N,A,R}
    csa
end

# These apply for broadcasted assignment operations, if the shifts are identical
@inline function Base.Broadcast.materialize!(dest::ShiftedArray{T,N,A,R}, src::ShiftedArray) where {T,N,A,R} 
    if shifts(dest) != shifts(src)
        error("Copyiing into a ShiftedArray of different shift is disallowed. Use the same shift or an ordinary array.")
    end
    Base.Broadcast.materialize!(dest.parent, src.parent)
end

function Base.Broadcast.copyto!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N}}) where {N}
     Base.Broadcast.materialize!(dest, bc)
     return dest
end

# This copy operation is performed when an expression (in bc) needs to be evaluated
function Base.Broadcast.copy(bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N}}) where {N}
    if only_shifted(bc)
        ElType = Base.Broadcast.combine_eltypes(bc.f, bc.args)
        # since there are only shifted arrays we can use the default
        if has_circ_type(bc)
            res = similar(bc, ElType, size(bc); shifts = shifts(bc), default = CircShift)
        else
            # calculate the default here
            res = similar(bc, ElType, size(bc); shifts = shifts(bc), default = default(bc))
        end
    else
        ElType = Base.Broadcast.combine_eltypes(bc.f, bc.args)
        bcr = remove_sa_broadcast(bc)
        res = similar(bcr, ElType, size(bcr))
    end
    return copyto!(res, bc)
end

# remove all the (circ-)shift part if all shifts are the same (or constants)
# @inline function materialize!(dest::ShiftedArray{T, N, A, R}, bc::Base.Broadcast.Broadcasted{ShiftedArrays.ShiftedArrayStyle{N, S}}) where {T, N, A, S, N, S, R}
@inline function Base.Broadcast.materialize!(dest::ShiftedArray{T, N, A, R}, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N}}) where {T, N, A, R}
    #     # get all not-shifted arrays and apply the materialize operations piecewise using array views
    return materialize_checkerboard!(dest.parent, bc, Tuple(1:N), shifts(dest), true; array_type=R)
end

# we cannot specialize the Broadcast style here, since the rhs may not contain a ShiftedArray and still wants to be assigned
@inline function Base.Broadcast.materialize!(dest::ShiftedArray{T,N,A,R}, bc::Base.Broadcast.Broadcasted{BT}) where {T,N,A,R,BT}
    materialize_checkerboard!(dest.parent, bc, Tuple(1:N), shifts(dest), true; array_type=R)
    return dest
end

# for ambiguous conflict resolution
@inline function Base.Broadcast.materialize!(dest::ShiftedArray{T,N,A,R}, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N2}}) where {T,N,A,R,N2}
    if shifts(dest) != S2
        error("assigment of ShiftedArray to another ShiftedArray needs to have the same shift.")
    end
    materialize_checkerboard!(dest.parent, bc, Tuple(1:N), wrapshift(size(dest) .- shifts(dest), size(dest)), true; default=R)
    return dest
end

@inline function Base.Broadcast.materialize!(dest::AbstractArray, bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N}}) where {N}
    materialize_checkerboard!(dest, bc, Tuple(1:N), nothing, false; array_type=Nothing)
    return dest
end

# This collect function needs to be defined to prevent the linear indexing to take over and just copy the raw (not shifted) data.
function Base.collect(src::ShiftedArray{T,N,A,R}) where {T,N,A,R}
    src = if (isa(src.parent,ShiftedArray))
        ShiftedArray(collect(src.parent), shifts(src); default=default(src))
    else
        src
    end
    bc = Base.Broadcast.broadcasted(identity, src)
    dest = similar(src.parent, eltype(src))
    materialize_checkerboard!(dest, bc, Tuple(1:N), shifts(src), false; array_type=R)
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
    materialize_checkerboard!(dest, bc, dims, myshift, dest_is_cs_array=false; array_type=CircShift) 

this function subdivides the array into tiles, which each needs to be processed individually via calls to `materialize!`.

|--------|
| a| b   |
|--|-----|---|
| c| dD  | C |
|--+-----|---|
   | B   | A |
   |---------|

"""
function materialize_checkerboard!(dest, bc, dims, myshift, dest_is_cs_array=false; array_type=CircShift) 
    dest = refine_view(dest)

    if isnothing(myshift)
        myshift = shifts(bc)
    end
    # gets Tuples of Tuples of 1D ranges (low and high) for each dimension
    cs_rngs, ns_rngs = generate_shift_ranges(dest, wrapshift(size(dest) .- myshift, size(dest)))
    nonflipped = nonflipped_source(myshift)
    # use the broadcast, with the ShiftedArrays which are not CircShiftedArrays replaced by the default values 
    bcd = replace_by_default_broadcast(bc)
    for n in CartesianIndices(ntuple((x)->2, ndims(dest)))
        cs_rng = Tuple(cs_rngs[n[d]][d] for d=1:ndims(dest))
        ns_rng = Tuple(ns_rngs[n[d]][d] for d=1:ndims(dest))
        dst_rng = ifelse(dest_is_cs_array, cs_rng, ns_rng)
        dst_rng = refine_shift_rng(dest, dst_rng)
        dst_view = @view dest[dst_rng...]

        bc1 = split_array_broadcast(bc, ns_rng, cs_rng)
        if (prod(size(dst_view)) > 0)
            if (Tuple(n) == nonflipped) # array_type <: CircShift || 
                @inbounds Base.Broadcast.materialize!(dst_view, bc1)
            else
                # check if there is any need to calculate the other quadrants.
                if (! isa(dest, ShiftedArray) || default(dest) == CircShift())
                    bc2 = split_array_broadcast(bcd, ns_rng, cs_rng)
                    @inbounds Base.Broadcast.materialize!(dst_view, bc2)
                end
            end
        end
    end
end
function materialize_checkerboard!(dest::ShiftedArray{T,N,A,R}, bc, dims, myshift, dest_is_cs_array=(R<:CircShift); array_type=R) where {T,N,A,R}
    @show "materialize_checkerboard SA"
    materialize_checkerboard!(dest, bc, dims, myshift, dest_is_cs_array; array_type=array_type) 
end

# identifies which quadrant corresponds to the original (non-flipped quadrant)
function nonflipped_source(myshift)
    (myshift.<=0) .+ 1
end

# some code which determines whether all arrays are shifted
@inline only_shifted(bc)  = true
@inline only_shifted(bc::Number)  = true
@inline only_shifted(bc::AbstractArray)  = false
@inline only_shifted(bc::ShiftedArray)  = true
@inline only_shifted(bc::Base.Broadcast.Broadcasted) = all(only_shifted.(bc.args))
@inline only_shifted(bc::Base.Broadcast.Extruded) = only_shifted(bc.x)

# These functions remove the ShiftArray in a broadcast and replace each by a view into the original array 
@inline split_array_broadcast(bc, noshift_rng, shift_rng) = bc
@inline split_array_broadcast(bc::Number, noshift_rng, shift_rng) = bc
@inline split_array_broadcast(bc::AbstractArray, noshift_rng, shift_rng) = @view bc[noshift_rng...]
@inline split_array_broadcast(bc::ShiftedArray, noshift_rng, shift_rng) = @view bc.parent[shift_rng...]
@inline split_array_broadcast(bc::ShiftedArray{T,N,A,R}, noshift_rng, shift_rng)  where {T,N,A,R} =  @view bc.parent[noshift_rng...]
@inline function split_array_broadcast(v::SubArray{T,N,P,I,L}, noshift_rng, shift_rng) where {T,N,P<:ShiftedArray,I,L}    
    new_cs = refine_view(v)
    new_shift_rng = refine_shift_rng(v, shift_rng)
    res = split_array_broadcast(new_cs, noshift_rng, new_shift_rng)
    return res
end

function split_array_broadcast(bc::Base.Broadcast.Broadcasted, noshift_rng, shift_rng)
    # Ref below protects the argument from broadcasting
    bc_modified = split_array_broadcast.(bc.args, Ref(noshift_rng), Ref(shift_rng))
    res = Base.Broadcast.broadcasted(bc.f, bc_modified...)
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
    return res
end

# leave all circshifted arrays in place but replace the shifted array by a single default number
@inline replace_by_default_broadcast(arg) = arg
@inline replace_by_default_broadcast(sa::ShiftedArray{T,N,A,R}) where {T,N,A,R} = ifelse(R<:CircShift, sa, default(sa))
function replace_by_default_broadcast(bc::Base.Broadcast.Broadcasted)
    # Ref below protects the argument from broadcasting
    bc_modified = replace_by_default_broadcast.(bc.args)
    res = Base.Broadcast.broadcasted(bc.f, bc_modified...)
    return res
end

# leave all circshifted arrays in place but replace the shifted array by a single default number
shifts(anything) = missing
shifts(::AbstractArray{T,N}) where {T,N} = missing
function shifts(bc::Base.Broadcast.Broadcasted)
    # Ref below protects the argument from broadcasting
    all_shifts = shifts.(bc.args)
    first_shift = coalesce(all_shifts...)
    if !all(skipmissing(all_shifts) .== Ref(first_shift))
        error("Shifts of arrays during broadcast differ. Please use `collect`.")
    end
    return first_shift
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

function Base.reverse(csa::ShiftedArray; dims=:)
    rev = Base.reverse(csa.parent; dims=dims)
    ShiftedArray(rev, .-shifts(csa), default=default(csa))
end

# these array isequal and == functions are defined to be compatible with the previous definition of equality (equal values only)
function Base.isequal(csa::ShiftedArray, arr::AbstractArray)
    if isequal(Ref(csa), Ref(arr))
        return true
    end
    return all(isequal.(csa, arr))
end
Base.isequal(arr::AbstractArray, csa::ShiftedArray) = isequal(csa, arr)
function Base.isequal(arr::ShiftedArray, csa::ShiftedArray)
    if isequal(Ref(csa), Ref(arr))
        return true
    end
    if isequal(default(arr), CircShift()) && isequal(default(csa), CircShift()) && shifts(arr)==shifts(csa)
        return isequal(arr.parent, csa.parent)
    end
    return all(isequal.(csa, arr))
end

# cases for views of ShiftedArray should still be added at some point.

function Base. ==(csa::ShiftedArray, arr::AbstractArray) 
    if isequal(Ref(csa), Ref(arr))
        return true
    end
    return all(.==(csa, arr))
end
Base. ==(arr::AbstractArray, csa::ShiftedArray) = (csa==arr)

function Base. ==(arr::ShiftedArray, csa::ShiftedArray)
    if isequal(Ref(csa), Ref(arr))
        return true
    end
    if default(arr)==CircShift() && default(csa) == CircShift() && shifts(arr)==shifts(csa)
        return arr.parent == csa.parent
    end
    return all(.==(csa, arr))
end

function Base.isapprox(csa::ShiftedArray, arr::AbstractArray; kwargs...) 
    if isequal(Ref(csa), Ref(arr))
        return true
    end
    return isapprox(collect(csa), arr; kwargs...)
end
Base.isapprox(arr::AbstractArray, csa::ShiftedArray; kwargs...) = isapprox(csa, arr; kwargs...)

function Base.isapprox(arr::ShiftedArray, csa::ShiftedArray; kwargs...)
    if isequal(Ref(csa), Ref(arr))
        return true
    end
    if default(arr)==CircShift() && default(csa) == CircShift() && shifts(arr)==shifts(csa)
        return isapprox(arr.parent, csa.parent; kwargs...)
    end
    return isapprox(collect(csa), arr; kwargs...)
end

# Base.isequal(arr::AbstractArray, csa::ShiftedArray) = isequal(csa, arr)
# Base.isequal(csa1::ShiftedArray, csa2::ShiftedArray)  = invoke(isequal, Tuple{ShiftedArray, AbstractArray}, csa1, csa2)
# Base. ==(csa::ShiftedArray, arr::AbstractArray) = isequal(csa, arr)
# Base. ==(arr::AbstractArray, csa::ShiftedArray) = isequal(csa, arr)
# Base. ==(csa1::ShiftedArray, csa2::ShiftedArray) = isequal(csa1,csa2)

function Base.copy(arr::ShiftedArray)
    collect(arr)
end

Base.eltype(arr::ShiftedArray{T,N,A,R})  where {T,N,A,R<:CircShift} = eltype(parent(arr))

# The code below supports the default-types for ShiftedArrays interacting with constants, which remain a ShiftedArray. 
propagate_default(f,a,b) = f(a,b)
propagate_default(f, a::Missing, b::AbstractArray) = missing
propagate_default(f, a::AbstractArray, b::Missing) = missing
propagate_default(f, a::Nothing, b::AbstractArray) = nothing
propagate_default(f, a::AbstractArray, b::Nothing) = nothing
#propagate_default(f, a::Base.Broadcast.Broadcasted, b) = Base.promote_op(Base.broadcast, typeof(f), typeof(a), typeof(b))
#propagate_default(f, a, ::Base.Broadcast.Broadcasted) = a
propagate_default(f, a::CircShift,b) = CircShift()
propagate_default(f, a, b::CircShift) = CircShift()
propagate_default(f, a::CircShift, b::CircShift) = CircShift()

function Base.broadcasted(f::Function, a::ShiftedArray, b::Number)
    if isa(b, Base.Broadcast.Broadcasted)
        a = collect(a)
        b = reshape(collect(b), size(b))
        return Base.broadcasted(f, a, b)
    else
        new_default = propagate_default(f,default(a), b)
        a = ShiftedArray(a.parent, shifts(a), default=new_default)
    end
    return invoke(Base.broadcasted, Tuple{typeof(f), AbstractArray, typeof(b)}, f, a, b)
end

function Base.broadcasted(f::Function, b::Number, a::ShiftedArray)
    if isa(b, Base.Broadcast.Broadcasted)
        a = collect(a)
        b = collect(b)
    else
        new_default = propagate_default(f, b, default(a))
        a = ShiftedArray(a.parent, shifts(a), default=new_default)
    end
    return invoke(Base.broadcasted, Tuple{typeof(f), typeof(b), AbstractArray}, f, b, a)
end

function Base.broadcasted(f::Function, a::ShiftedArray, b::ShiftedArray)
    new_default = propagate_default(f,default(a), default(b))
    if shifts(a) != shifts(b)
        error("shifts ($(shifts(a)) and $(shifts(b))) of both arrays need to be equal.")
    end
    raw = f.(a.parent, b.parent)
    res = ShiftedArray(raw, shifts(a), default=new_default)
    return res
end

function Base.similar(arr::ShiftedArray, eltp::Type, dims::Tuple{Int64, Vararg{Int64, N}}) where {N}
    na = similar(arr.parent, eltp, dims)
    # the results-type depends on whether the result size is the same or not. Same size can remain ShiftedArray.
    # its important that a shifted array is the result for reductions on CircShiftedArray, since only then the broadcasting works
    # Since similar cannot infer the shift information when a sub-range ws created e.g. sv[1:3] 
    return na # ifelse(size(arr)==dims, na, ShiftedArray(na, shifts(arr); default=default(arr)))
end

# specialized version for CircShiftArray which removes the Union Type
function Base.similar(arr::ShiftedArray, ::Type{Union{CircShift,T}}, dims::Tuple{Int64, Vararg{Int64, N}}) where {T,N}
    na = similar(arr.parent, T, dims)
    return na 
end

Base.similar(arr::ShiftedArray, eltp::Type) = similar(arr, eltp, size(arr))
Base.similar(arr::ShiftedArray, dims::Tuple{Int64, Vararg{Int64, N}}) where {N} = similar(arr, eltype(arr), dims)
Base.similar(arr::ShiftedArray) = similar(arr, eltype(arr), size(arr))

# this should be used for sum, max etc.
# function Base.reduce(op, itr::ShiftedArray; init=init)
#     @show "reduce"
#     reduce(op, itr.parent; init=init)
# end

# The order of non-broadcast-reduction does not matter, but ONLY, if the dims keyword is not used.
function Base.mapreduce(mapf, op, a::ShiftedArray; dims=:, kw...)
    res = mapreduce(mapf, op, a.parent; dims=dims, kw...)
    if !isa(dims, Colon)
        return ShiftedArray(res, shifts(a), default=default(a))
    end
    return res
end

Base.any(a::ShiftedArray; dims=:) = any(a.parent; dims)
Base.all(a::ShiftedArray; dims=:) = all(a.parent; dims)

# function Base.mapreducedim!(f, op, B::ShiftedArray, A)
#     @show "reducedim! 1"
#     Base.mapreducedim!(f, op, B.parent, A)
# end

# function Base.mapreducedim!(f, op, B::ShiftedArray, A::ShiftedArray)
#     @show "reducedim! 2"
#     Base.mapreducedim!(f, op, B.parent, A.parent)
# end

# This one is called for reduce operations to allocate like similar, but always a ShiftedArray
function Base.reducedim_initarray(arr::ShiftedArray, region, init, r::Type{R}) where R
    @show "reducedim_initarray"
    res = invoke(Base.reducedim_initarray, Tuple{AbstractArray, typeof(region), typeof(init), typeof(r)}, arr, region,init,r)
    return ShiftedArray(res, shifts(arr), default=default(arr))
end

function Base.similar(bc::Base.Broadcast.Broadcasted{ShiftedArrayStyle{N},Ax,F,Args}, et::ET, dims::Any; shifts=shifts(bc), default=default(bc)) where {N,ET,Ax,F,Args}
    # remove the ShiftedArrayStyle from broadcast to call the original "similar" function 
    bc_tmp = remove_sa_broadcast(bc) #Base.Broadcast.Broadcasted{Base.Broadcast.DefaultArrayStyle{N}}(bc.f, bc.args, bc.axes)
    res = invoke(Base.Broadcast.similar, Tuple{typeof(bc_tmp),ET,Any}, bc_tmp, et, dims)
    # if all broadcast members are shifted, also return a shifted version
    if only_shifted(bc)
        return ShiftedArray(res, shifts; default=default)
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
        # unfortunately we have to collect here
        show(ioc, mm, collect(cs))
        buffer = String(take!(buffer))
        lines = split(buffer,"\n")
        lines[1] = string(typeof(cs)) * ":"
        print(io, join(lines,"\n"))
    else
        invoke(Base.show, Tuple{IO, typeof(mm), AbstractArray}, io, mm, cs) 
    end
end

