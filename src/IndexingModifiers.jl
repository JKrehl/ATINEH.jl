import Base: convert, (∘), getindex, setindex!, first, tail, @propagate_inbounds

export addindex!
export AbstractIndexingModifier, MappedArray, MappedArray_byMap, IndexMapChain, IndexIdentity, PermuteIndices

IndexTypes = Union{Number, Tuple, AffineTransform}

@inline addindex!(A::AbstractArray, value, i...) = begin @boundscheck checkbounds(A, i...); @inbounds A[i...] += value end

"abstract index map"
abstract type AbstractIndexingModifier end

"an array annotated with an index map"
struct MappedArray{T, N, A<:AbstractArray, M<:AbstractIndexingModifier} <: AbstractArray{T,N}
    array::A
    map::M
    MappedArray(array::A, map::M) where {T, N, A<:AbstractArray{T,N}, M<:AbstractIndexingModifier} = new{T,N,A,M}(array, map)
    MappedArray{T, N}(array::A, map::M) where {T, N, A<:AbstractArray, M<:AbstractIndexingModifier} = new{T,N,A,M}(array, map)
end
MappedArray_byMap{I} = MappedArray{T,N,A,I} where {T, N, A}

@inline size(ma::MappedArray) = size(ma.array)

@propagate_inbounds getindex(A::AbstractArray, m::AbstractIndexingModifier, x::Vararg) = getindex(MappedArray(A, m), x...)
@propagate_inbounds setindex!(A::AbstractArray, val,  m::AbstractIndexingModifier, x::Vararg) = setindex!(MappedArray(A, m), val, x...)
@propagate_inbounds addindex!(A::AbstractArray, val,  m::AbstractIndexingModifier, x::Vararg) = addindex!(MappedArray(A, m), val, x...)

"index map without effect"
struct IndexIdentity <: AbstractIndexingModifier end

@propagate_inbounds getindex(A::MappedArray_byMap{IndexIdentity}, x::Vararg{<:IndexTypes}) = getindex(A.array, x...)
@propagate_inbounds setindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = setindex!(A.array, val, x...)
@propagate_inbounds addindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = addindex!(A.array, val, x...)


"""
    a fun helper function
"""
@generated function valrangetuple(::Type{Val{N}}) where N
    quote
        $(Expr(:meta, :inline))
        Val{$(Expr(:tuple, (1:N)...))}()
    end
end


"""
    struct PermuteIndices{P} <: AbstractIndexingModifier
    P is a tuple of ints permuting (or dropping or repeating) indices
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Val{P}) where P = new{P}()
"""
struct PermuteIndices{P} <: AbstractIndexingModifier
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Val{P}) where P = new{P}()
end

PermuteIndices(P::Vararg{Int}) = PermuteIndices{P}()

@generated function getindex{P,N}(A::MappedArray_byMap{PermuteIndices{P}}, x::Vararg{<:IndexTypes,N})
    @assert all(map(i->i<=N,P))
    quote
        $(Expr(:meta, :inline, :propagate_inbounds))
        @inbounds @ntuple($N, i->ix_i) = x
        getindex(A.array, $((Symbol(:ix_, i) for i in P)...))
    end
end

@generated function setindex!{P,N}(A::MappedArray_byMap{PermuteIndices{P}}, val, x::Vararg{<:IndexTypes,N})
    @assert all(map(i->i<=N,P))
    quote
        $(Expr(:meta, :inline, :propagate_inbounds))
        @inbounds @ntuple($N, i->ix_i) = x
        setindex!(A.array, val, $((Symbol(:ix_, i) for i in P)...))
    end
end

@generated function addindex!{P,N}(A::MappedArray_byMap{PermuteIndices{P}}, val, x::Vararg{<:IndexTypes,N})
    @assert all(map(i->i<=N,P))
    quote
        $(Expr(:meta, :inline, :propagate_inbounds))
        @inbounds @ntuple($N, i->ix_i) = x
        addindex!(A.array, val, $((Symbol(:ix_, i) for i in P)...))
    end
end
