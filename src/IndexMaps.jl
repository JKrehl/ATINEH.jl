import Base: convert, (∘), getindex, setindex!, first, tail

export addindex!
export AbstractIndexMap, IndexMappedArray, IndexMapChain, IndexIdentity, PermuteIndices

init(x) = reverse(tail(reverse(x)))

addindex!(A::AbstractArray, value, i::Vararg{Number}) = A[i...] += value

"abstract index map"
abstract type AbstractIndexMap end

"an array annotated with an index map"
struct IndexMappedArray{T, N, A<:AbstractArray{T,N}, I<:AbstractIndexMap} <: AbstractArray{T,N}
    a::A
    i::I
    IndexMappedArray(a::A, i::I) where {T, N, A<:AbstractArray{T,N}, I<:AbstractIndexMap} = new{T,N,A,I}(a,i)
end

@inline getindex(A::AbstractArray, m::AbstractIndexMap, x...) = getindex(IndexMappedArray(A, m), x...)
@inline getindex(A::IndexMappedArray, x::Vararg{Number}) = getindex(A.a, A.i, x...)

@inline setindex!(A::AbstractArray, val,  m::AbstractIndexMap, x...) = setindex!(IndexMappedArray(A, m), val, x...)
@inline setindex!(A::IndexMappedArray, val, x::Vararg{Number}) = setindex!(A.a, val, A.i, x...)

@inline addindex!(A::AbstractArray, val,  m::AbstractIndexMap, x...) = addindex!(IndexMappedArray(A, m), val, x...)
@inline addindex!(ima::IndexMappedArray, val, x::Vararg{Number}) = addindex!(ima.a, val, ima.i, x...)

"chain of index maps"
struct IndexMapChain{T<:Tuple{Vararg{<: AbstractIndexMap}}} <: AbstractIndexMap
    transforms::T
end

IndexMapChain(x...) = IndexMapChain(x)

@inline (∘)(A::AbstractIndexMap, B::AbstractIndexMap) = IndexMapChain(A, B)
@inline (∘)(A::IndexMapChain, B::AbstractIndexMap) = IndexMapChain(A.transforms..., B)
@inline (∘)(A::AbstractIndexMap, B::IndexMapChain) = IndexMapChain(A, B.transforms...)
@inline (∘)(A::IndexMapChain, B::IndexMapChain) = IndexMapChain(A.transforms..., B.transforms...)

@inline getindex(A::AbstractArray, imc::IndexMapChain{Tuple{}}, x::Vararg{Number}) = getindex(A, x...)
@inline getindex(A::AbstractArray, imc::IndexMapChain, x::Vararg{Number}) = getindex(IndexMappedArray(A, IndexMapChain(init(imc.transforms))), x...)

@inline setindex!(A::AbstractArray, val, imc::IndexMapChain{Tuple{}}, x::Vararg{Number}) = setindex!(A, val, x...)
@inline setindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg{Number}) = setindex!(IndexMappedArray(A, IndexMapChain(init(imc.transforms))), val, last(imc.transforms), x...)

@inline addindex!(A::AbstractArray, val, imc::IndexMapChain{Tuple{}}, x::Vararg{Number}) = addindex!(A, val, x...)
@inline addindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg{Number}) = addindex!(IndexMappedArray(A, IndexMapChain(init(imc.transforms))), val, last(imc.transforms), x...)

"index map without effect"
struct IndexIdentity <: AbstractIndexMap end

@inline getindex(A::AbstractArray, ::IndexIdentity, x::Vararg{Number}) = getindex(A, x...)

@inline setindex!(A::AbstractArray, val, ::IndexIdentity, x::Vararg{Number}) = setindex!(A, val, x...)

@inline addindex!(A::AbstractArray, val, ::IndexIdentity, x::Vararg{Number}) = addindex!(A, val, x...)

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

@inline @generated function getindex{P}(A::AbstractArray, p::PermuteIndices{P}, x::Vararg{Number})
    :($(Expr(:meta, :inline)); getindex(A, $([:(x[$i]) for i in P]...)))
end

@inline @generated function setindex!{P}(A::AbstractArray, val, p::PermuteIndices{P}, x::Vararg{Number})
    :($(Expr(:meta, :inline)); getindex(A, val, $([:(x[$i]) for i in P]...)))
end

@inline @generated function addindex!{P}(A::AbstractArray, val, p::PermuteIndices{P}, x::Vararg{Number})
    :($(Expr(:meta, :inline)); getindex(A, val, $([:(x[$i]) for i in P]...)))
end
