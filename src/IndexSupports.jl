import Base: size, getindex, (*), (+), convert

export IndexSupportPoint, IndexReturningArray, FlatIndexReturningArray, assemble

struct IndexSupportPoint{N,V,I<:Tuple{Vararg{Number}}}
    val::V
    idx::I
    IndexSupportPoint(value::V, index::I) where {N, V, I<:NTuple{N, Number}} = new{N,V,I}(value, index)
end

struct IndexReturningArray{N, V, I<:NTuple{N, Integer}} <: AbstractArray{Vector{IndexSupportPoint{N, V, I}},N}
    _size::I
    IndexReturningArray{V}(_size::I) where {N,V,I<:NTuple{N, Integer}} = new{N,V,I}(_size)
    IndexReturningArray(_size::I) where {N,I<:NTuple{N, Integer}} = new{N,Float64,I}(_size)
end

size(iar::IndexReturningArray) = iar._size
size(iar::IndexReturningArray, i::Int) = iar._size[i]

getindex{N,V}(iar::IndexReturningArray{N,V}, idx::Vararg{Int, N}) = [IndexSupportPoint(one(V), idx)]

struct FlatIndexReturningArray{N, V, I<:NTuple{N, Integer}} <: AbstractArray{Vector{IndexSupportPoint{N, V, Tuple{Int}}},N}
    _size::I
    FlatIndexReturningArray{V}(_size::I) where {N,V,I<:NTuple{N, Integer}} = new{N,V,I}(_size)
    FlatIndexReturningArray(_size::I) where {N,I<:NTuple{N, Integer}} = new{N,Float64,I}(_size)
end

size(fiar::FlatIndexReturningArray) = fiar._size
size(fiar::FlatIndexReturningArray, i::Int) = fiar._size[i]

getindex{N,V}(fiar::FlatIndexReturningArray{N,V}, idx::Vararg{Int, N}) = [IndexSupportPoint(one(V), (sub2ind(fiar, idx...),))]

(*){N,V,I}(val, isp::IndexSupportPoint{N,V,I}) = IndexSupportPoint(val*isp.val, isp.idx)
(+){N,V,I}(isps1::Vector{IndexSupportPoint{N,V,I}}, isps2::Vector{IndexSupportPoint{N,V,I}}) = vcat(isps1, isps2)

assemble{N,V,I}(isps::Vector{IndexSupportPoint{N,V,I}}) = ([isp.val for isp in isps], ([isp.idx[i] for isp in isps] for i in 1:N)...)
