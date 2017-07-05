import Base: convert, (∘), getindex, setindex!, first, tail

export addindex!
export AbstractIndexMap, MappedArray, MappedArray_byMap, IndexMapChain, IndexIdentity, PermuteIndices

IndexTypes = Union{Number, Tuple, AffineTransform}

addindex!(A::AbstractArray, value, i...) = A[i...] += value

"abstract index map"
abstract type AbstractIndexMap end

"an array annotated with an index map"
struct MappedArray{T, N, A<:AbstractArray, M<:AbstractIndexMap} <: AbstractArray{T,N}
    a::A
    m::M
    MappedArray(a::A, m::M) where {T, N, A<:AbstractArray{T,N}, M<:AbstractIndexMap} = new{T,N,A,M}(a,m)
    MappedArray{T, N}(a::A, m::M) where {T, N, A<:AbstractArray, M<:AbstractIndexMap} = new{T,N,A,M}(a,m)
end
MappedArray_byMap{I} = MappedArray{T,N,A,I} where {T, N, A}

@inline size(ma::MappedArray) = size(ma.a)

@inline getindex(A::AbstractArray, m::AbstractIndexMap, x::Vararg) = getindex(MappedArray(A, m), x...)
@inline setindex!(A::AbstractArray, val,  m::AbstractIndexMap, x::Vararg) = setindex!(MappedArray(A, m), val, x...)
@inline addindex!(A::AbstractArray, val,  m::AbstractIndexMap, x::Vararg) = addindex!(MappedArray(A, m), val, x...)

"chain of index maps"
struct IndexMapChain{T<:Tuple{Vararg{<: AbstractIndexMap}}} <: AbstractIndexMap
    maps::T
end

IndexMapChain(x...) = IndexMapChain(x)

@inline (∘)(A::AbstractIndexMap, B::AbstractIndexMap) = IndexMapChain(A, B)
@inline (∘)(A::IndexMapChain, B::AbstractIndexMap) = IndexMapChain(A.maps..., B)
@inline (∘)(A::AbstractIndexMap, B::IndexMapChain) = IndexMapChain(A, B.maps...)
@inline (∘)(A::IndexMapChain, B::IndexMapChain) = IndexMapChain(A.maps..., B.maps...)

@inline getindex(A::AbstractArray, imc::IndexMapChain{Tuple{}}, x::Vararg) = getindex(A, x...)
@inline getindex(A::AbstractArray, imc::IndexMapChain, x::Vararg) = getindex(MappedArray(A, first(imc.maps)), IndexMapChain(tail(imc.maps)), x...)

@inline setindex!(A::AbstractArray, val, imc::IndexMapChain{Tuple{}}, x::Vararg) = setindex!(A, val, x...)
@inline setindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg) = setindex!(MappedArray(A, first(imc.maps)), val, IndexMapChain(tail(imc.maps)), x...)

@inline addindex!(A::AbstractArray, val, imc::IndexMapChain{Tuple{}}, x::Vararg) = addindex!(A, val, x...)
@inline addindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg) = addindex!(MappedArray(A, first(imc.maps)), val, IndexMapChain(tail(imc.maps)), x...)

"index map without effect"
struct IndexIdentity <: AbstractIndexMap end

@inline getindex(A::MappedArray_byMap{IndexIdentity}, x::Vararg{<:IndexTypes}) = getindex(A.a, x...)
@inline setindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = setindex!(A.a, val, x...)
@inline addindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = addindex!(A.a, val, x...)


"""
    struct PermuteIndices{P} <: AbstractIndexMap
    P is a tuple of ints permuting (or dropping or repeating) indices
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Type{Val{P}}) where P = new{P}()
"""
struct PermuteIndices{P} <: AbstractIndexMap
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Type{Val{P}}) where P = new{P}()
end

PermuteIndices(P::Vararg{Int}) = PermuteIndices{P}()

@inline @generated function getindex{P}(A::MappedArray_byMap{PermuteIndices{P}}, x::Vararg{<:IndexTypes})
    :($(Expr(:meta, :inline)); getindex(A.a, $([:(x[$i]) for i in P]...)))
end

@inline @generated function setindex!{P}(A::MappedArray_byMap{PermuteIndices{P}}, x::Vararg{<:IndexTypes})
    :($(Expr(:meta, :inline)); getindex(A.a, val, $([:(x[$i]) for i in P]...)))
end

@inline @generated function addindex!{P}(A::MappedArray_byMap{PermuteIndices{P}}, x::Vararg{<:IndexTypes})
    :($(Expr(:meta, :inline)); getindex(A.a, val, $([:(x[$i]) for i in P]...)))
end
