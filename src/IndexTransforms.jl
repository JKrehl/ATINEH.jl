import Base: convert, (∘), getindex, setindex!, first, tail

export AbstractIndexTransform, IndexTransformChain, IndexIdentity, addindex!

NAbstractArray{N,T} = AbstractArray{T,N}

abstract type AbstractIndexTransform{N} end

"container for multiple, or one, or none index transforms"
struct IndexTransformChain{N, T<:Tuple{Vararg{AbstractIndexTransform{N}}}}
    transforms::T
    IndexTransformChain{N}(transforms::T=()) where{N,T<:Tuple{Vararg{AbstractIndexTransform{N}}}} = new{N,T}(transforms)
    IndexTransformChain{N,T}(transforms::T=()) where{N,T<:Tuple{Vararg{AbstractIndexTransform{N}}}} = new{N,T}(transforms)
end

convert{N,T<:Tuple{Vararg{AbstractIndexTransform{N}}}}(::Type{IndexTransformChain}, transforms::T) = IndexTransformChain{N,T}(transforms)

(∘){N}(it1::AbstractIndexTransform{N}, it2::AbstractIndexTransform{N}) = IndexTransformChain{N}((it1,it2))
(∘){N}(itc::IndexTransformChain{N}, it::AbstractIndexTransform{N}) = IndexTransformChain{N}((itc.transforms..., it))
(∘){N}(it::AbstractIndexTransform{N}, itc::IndexTransformChain{N}) = IndexTransformChain{N}((it, itc.transforms...))
(∘){N}(itc1::IndexTransformChain{N}, itc2::IndexTransformChain{N}) = IndexTransformChain{N}((itc1.transforms..., itc2.transforms...))

# helpers
rhead(a) = first(reverse(a))
rtail(a) = reverse(tail(reverse(a)))


# to pack indices from vararg into tuple, so tuple of types can be resolved
@inline getindex{N}(A::NAbstractArray{N}, it::AbstractIndexTransform{N}, idx::Vararg{Number,N}) = getindex(A, IndexTransformChain{N}(), it, idx)
@inline getindex{N}(A::NAbstractArray{N}, itc::IndexTransformChain{N}, it::AbstractIndexTransform{N}, idx::Vararg{Number,N}) = getindex(A, itc, it, idx)

# dispatch elements of the chain onto the indices
@inline getindex{N}(A::NAbstractArray{N}, itc::IndexTransformChain{N, Tuple{}}, idx::Vararg{Number,N}) = getindex(A, idx...)
@inline getindex{N}(A::NAbstractArray{N}, itc::IndexTransformChain{N}, idx::Vararg{Number,N}) = getindex(A, IndexTransformChain{N}(rtail(itc.transforms)), rhead(itc.transforms), idx...)

# accumulate index transforms into chain till only one index transform in front of the indices remains
@inline getindex{N}(A::NAbstractArray{N}, it1::Union{AbstractIndexTransform{N}, IndexTransformChain{N}}, it2::Union{AbstractIndexTransform{N}, IndexTransformChain{N}}, x...) = getindex(A, it1 ∘ it2, x...)


# same for setindex!
@inline setindex!{N}(A::NAbstractArray{N}, val, it::AbstractIndexTransform{N}, idx::Vararg{Number,N}) = setindex!(A, val, IndexTransformChain{N}(), it, idx)
@inline setindex!{N}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, it::AbstractIndexTransform{N}, idx::Vararg{Number,N}) = setindex!(A, val, itc, it, idx)
@inline setindex!{N}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N, Tuple{}}, idx::Vararg{Number,N}) = setindex!(A, val, idx...)
@inline setindex!{N}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, idx::Vararg{Number,N}) = setindex!(A, val, IndexTransformChain{N}(rtail(itc.transforms)), rhead(itc.transforms), idx...)
@inline setindex!{N}(A::NAbstractArray{N}, val, it1::Union{AbstractIndexTransform{N}, IndexTransformChain{N}}, it2::Union{AbstractIndexTransform{N}, IndexTransformChain{N}}, x...) = setindex!(A, val, it1 ∘ it2, x...)


# and the same for addindex!, after it's defined
addindex!{T,N,V}(A::AbstractArray{T,N}, value::V, i::Vararg{Integer, N}) = A[i...] += value
@inline addindex!{N}(A::NAbstractArray{N}, val, it::AbstractIndexTransform{N}, idx::Vararg{Number,N}) = addindex!(A, val, IndexTransformChain{N}(), it, idx)
@inline addindex!{N}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, it::AbstractIndexTransform{N}, idx::Vararg{Number,N}) = addindex!(A, val, itc, it, idx)
@inline addindex!{N}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N, Tuple{}}, idx::Vararg{Number,N}) = addindex!(A, val, idx...)
@inline addindex!{N}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, idx::Vararg{Number,N}) = addindex!(A, val, IndexTransformChain{N}(rtail(itc.transforms)), rhead(itc.transforms), idx...)
@inline addindex!{N}(A::NAbstractArray{N}, val, it1::Union{AbstractIndexTransform{N}, IndexTransformChain{N}}, it2::Union{AbstractIndexTransform{N}, IndexTransformChain{N}}, x...) = addindex!(A, val, it1 ∘ it2, x...)


"index transform with no effect"
struct IndexIdentity{N} <: AbstractIndexTransform{N}
end

@inline getindex{N, I<:NTuple{N,Number}}(A::NAbstractArray{N}, itc::IndexTransformChain{N}, ::IndexIdentity{N}, idx::I) = getindex(A, itc, idx...)
@inline setindex!{N, I<:NTuple{N,Number}}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, ::IndexIdentity{N}, idx::I) = setindex!(A, val, itc, idx...)
@inline addindex!{N, I<:NTuple{N,Number}}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, ::IndexIdentity{N}, idx::I) = addindex!(A, val, itc, idx...)
