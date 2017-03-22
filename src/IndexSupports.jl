using Base.Cartesian
import Base: size, getindex, (*), (+), convert

export IndexSupportPoint, IndexReturningArray, FlatIndexReturningArray, assemble

struct IndexSupportPoint{N,V,I<:Tuple{Vararg{Number}}}
    val::V
    idx::I
    IndexSupportPoint(value::V, index::I) where {N, V, I<:NTuple{N, Number}} = new{N,V,I}(value, index)
    IndexSupportPoint{N}(value::V, index::I) where {N, V, I<:Tuple{Vararg{Number}}} = new{N,V,I}(value, index)
    IndexSupportPoint{N,V,I}(value::V, index::I) where {N, V, I<:Tuple{Vararg{Number}}} = new{N,V,I}(value, index)
end

@generated convert{N, V, IN, I<:NTuple{IN}}(::Type{IndexSupportPoint{N,V,I}}, val::Number) = :(IndexSupportPoint{$N, $V, $I}($V(val), $I(@ntuple $IN i->1)))

struct IndexReturningArray{N, V, I<:NTuple{N, Integer}} <: AbstractArray{Tuple{IndexSupportPoint{N, V, I}},N}
    _size::I
    IndexReturningArray{V}(_size::I) where {N,V,I<:NTuple{N, Integer}} = new{N,V,I}(_size)
    IndexReturningArray(_size::I) where {N,I<:NTuple{N, Integer}} = new{N,Float64,I}(_size)
end

size(iar::IndexReturningArray) = iar._size
size(iar::IndexReturningArray, i::Int) = iar._size[i]

@inline getindex{N,V,I}(iar::IndexReturningArray{N,V,I}, idx::Vararg{Int, N}) = (IndexSupportPoint(one(V), idx),)

struct FlatIndexReturningArray{N, V, I<:NTuple{N, Integer}} <: AbstractArray{Tuple{IndexSupportPoint{N, V, Tuple{Int}}},N}
    _size::I
    FlatIndexReturningArray{V}(_size::I) where {N,V,I<:NTuple{N, Integer}} = new{N,V,I}(_size)
    FlatIndexReturningArray(_size::I) where {N,I<:NTuple{N, Integer}} = new{N,Float64,I}(_size)
end

size(fiar::FlatIndexReturningArray) = fiar._size
size(fiar::FlatIndexReturningArray, i::Int) = fiar._size[i]

@inline getindex{N,V,I}(fiar::FlatIndexReturningArray{N,V,I}, idx::Vararg{Int, N}) = (IndexSupportPoint{N}(one(V), (sub2ind(fiar, idx...),)),)

(*){N,V,I}(val, isps::Tuple{Vararg{IndexSupportPoint{N,V,I}}}) = map(isp -> IndexSupportPoint(val*isp.val, isp.idx), isps)
(+){N,V,I}(isps1::Tuple{Vararg{IndexSupportPoint{N,V,I}}}, isps2::Tuple{Vararg{IndexSupportPoint{N,V,I}}}) = (isps1..., isps2...)

assemble{N,V,I}(isps::Tuple{Vararg{IndexSupportPoint{N,V,I}}}) = ([isp.val for isp in isps], ([isp.idx[i] for isp in isps] for i in 1:N)...)
