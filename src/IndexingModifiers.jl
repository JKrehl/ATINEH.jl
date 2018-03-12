import Base: convert, (∘), getindex, setindex!, first, tail, @propagate_inbounds

export addindex!
export AbstractIndexingModifier, MappedArray, MappedArray_byMap, IndexMapChain, IndexIdentity, PermuteIndices

IndexTypes = Union{Number, Tuple, AffineTransform}

@inline addindex!(A::AbstractArray, value, i...) = begin @boundscheck checkbounds(A, i...); @inbounds A[i...] += value end

"abstract index map"
abstract type AbstractIndexingModifier end

"an array annotated with an index map"
struct MappedArray{T, N, A<:AbstractArray, M<:AbstractIndexingModifier} <: AbstractArray{T,N}
    a::A
    m::M
    MappedArray(a::A, m::M) where {T, N, A<:AbstractArray{T,N}, M<:AbstractIndexingModifier} = new{T,N,A,M}(a,m)
    MappedArray{T, N}(a::A, m::M) where {T, N, A<:AbstractArray, M<:AbstractIndexingModifier} = new{T,N,A,M}(a,m)
end
MappedArray_byMap{I} = MappedArray{T,N,A,I} where {T, N, A}

@inline size(ma::MappedArray) = size(ma.a)

@propagate_inbounds getindex(A::AbstractArray, m::AbstractIndexingModifier, x::Vararg) = getindex(MappedArray(A, m), x...)
@propagate_inbounds setindex!(A::AbstractArray, val,  m::AbstractIndexingModifier, x::Vararg) = setindex!(MappedArray(A, m), val, x...)
@propagate_inbounds addindex!(A::AbstractArray, val,  m::AbstractIndexingModifier, x::Vararg) = addindex!(MappedArray(A, m), val, x...)

"chain of index maps"
struct IndexMapChain{T<:Tuple{Vararg{<: AbstractIndexingModifier}}} <: AbstractIndexingModifier
    maps::T
end

IndexMapChain(x...) = IndexMapChain(x)

@inline (∘)(A::AbstractIndexingModifier, B::AbstractIndexingModifier) = IndexMapChain(A, B)
@inline (∘)(A::IndexMapChain, B::AbstractIndexingModifier) = IndexMapChain(A.maps..., B)
@inline (∘)(A::AbstractIndexingModifier, B::IndexMapChain) = IndexMapChain(A, B.maps...)
@inline (∘)(A::IndexMapChain, B::IndexMapChain) = IndexMapChain(A.maps..., B.maps...)

@propagate_inbounds getindex(A::AbstractArray, ::IndexMapChain{Tuple{}}, x::Vararg) = getindex(A, x...)
@propagate_inbounds getindex(A::AbstractArray, imc::IndexMapChain, x::Vararg) = getindex(MappedArray(A, first(imc.maps)), IndexMapChain(tail(imc.maps)), x...)

@propagate_inbounds setindex!(A::AbstractArray, val, ::IndexMapChain{Tuple{}}, x::Vararg) = setindex!(A, val, x...)
@propagate_inbounds setindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg) = setindex!(MappedArray(A, first(imc.maps)), val, IndexMapChain(tail(imc.maps)), x...)

@propagate_inbounds addindex!(A::AbstractArray, val, ::IndexMapChain{Tuple{}}, x::Vararg) = addindex!(A, val, x...)
@propagate_inbounds addindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg) = addindex!(MappedArray(A, first(imc.maps)), val, IndexMapChain(tail(imc.maps)), x...)

"index map without effect"
struct IndexIdentity <: AbstractIndexingModifier end

@propagate_inbounds getindex(A::MappedArray_byMap{IndexIdentity}, x::Vararg{<:IndexTypes}) = getindex(A.a, x...)
@propagate_inbounds setindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = setindex!(A.a, val, x...)
@propagate_inbounds addindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = addindex!(A.a, val, x...)


"""
    struct PermuteIndices{P} <: AbstractIndexingModifier
    P is a tuple of ints permuting (or dropping or repeating) indices
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Type{Val{P}}) where P = new{P}()
"""
struct PermuteIndices{P} <: AbstractIndexingModifier
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Type{Val{P}}) where P = new{P}()
end

PermuteIndices(P::Vararg{Int}) = PermuteIndices{P}()

@propagate_inbounds @generated function getindex{P}(A::MappedArray_byMap{PermuteIndices{P}}, x::Vararg{<:IndexTypes})
    :($(Expr(:meta, :inline)); getindex(A.a, $([:(x[$i]) for i in P]...)))
end

@propagate_inbounds @generated function setindex!{P}(A::MappedArray_byMap{PermuteIndices{P}}, val, x::Vararg{<:IndexTypes})
    :($(Expr(:meta, :inline)); setindex!(A.a, val, $([:(x[$i]) for i in P]...)))
end

@propagate_inbounds @generated function addindex!{P}(A::MappedArray_byMap{PermuteIndices{P}}, val, x::Vararg{<:IndexTypes})
    :($(Expr(:meta, :inline)); addindex!(A.a, val, $([:(x[$i]) for i in P]...)))
end
