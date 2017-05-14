import Base: convert, (∘), getindex, setindex!, first, tail

export addindex!
export AbstractIndexMap, IndexMappedArray, IndexMapChain, IndexIdentity

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

getindex(A::AbstractArray, m::AbstractIndexMap, x...) = getindex(IndexMappedArray(A, m), x...)
getindex(A::IndexMappedArray, x::Vararg{Number}) = getindex(A.a, A.i, x...)

setindex!(A::AbstractArray, val,  m::AbstractIndexMap, x...) = setindex!(IndexMappedArray(A, m), val, x...)
setindex!(A::IndexMappedArray, val, x::Vararg{Number}) = setindex!(A.a, val, A.i, x...)

addindex!(A::AbstractArray, val,  m::AbstractIndexMap, x...) = addindex!(IndexMappedArray(A, m), val, x...)
addindex!(ima::IndexMappedArray, val, x::Vararg{Number}) = addindex!(ima.a, val, ima.i, x...)

"chain of index maps"
struct IndexMapChain{T<:Tuple{Vararg{<: AbstractIndexMap}}} <: AbstractIndexMap
    transforms::T
end

IndexMapChain(x...) = IndexMapChain(x)

(∘)(A::AbstractIndexMap, B::AbstractIndexMap) = IndexMapChain(A, B)
(∘)(A::IndexMapChain, B::AbstractIndexMap) = IndexMapChain(A.transforms..., B)
(∘)(A::AbstractIndexMap, B::IndexMapChain) = IndexMapChain(A, B.transforms...)
(∘)(A::IndexMapChain, B::IndexMapChain) = IndexMapChain(A.transforms..., B.transforms...)

getindex(A::AbstractArray, imc::IndexMapChain{Tuple{}}, x::Vararg{Number}) = getindex(A, x...)
getindex(A::AbstractArray, imc::IndexMapChain, x::Vararg{Number}) = getindex(IndexMappedArray(A, IndexMapChain(init(imc.transforms))), x...)

setindex!(A::AbstractArray, val, imc::IndexMapChain{Tuple{}}, x::Vararg{Number}) = setindex!(A, val, x...)
setindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg{Number}) = setindex!(IndexMappedArray(A, IndexMapChain(init(imc.transforms))), val, last(imc.transforms), x...)

addindex!(A::AbstractArray, val, imc::IndexMapChain{Tuple{}}, x::Vararg{Number}) = addindex!(A, val, x...)
addindex!(A::AbstractArray, val, imc::IndexMapChain, x::Vararg{Number}) = addindex!(IndexMappedArray(A, IndexMapChain(init(imc.transforms))), val, last(imc.transforms), x...)

"index map without effect"
struct IndexIdentity <: AbstractIndexMap end

getindex(A::AbstractArray, ::IndexIdentity, x::Vararg{Number}) = getindex(A, x...)

setindex!(A::AbstractArray, val, ::IndexIdentity, x::Vararg{Number}) = setindex!(A, val, x...)

addindex!(A::AbstractArray, val, ::IndexIdentity, x::Vararg{Number}) = addindex!(A, val, x...)
