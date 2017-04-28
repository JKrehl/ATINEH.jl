using Base.Cartesian
import Base: size, getindex, (*), (+), convert, first, tail, start, next, done, eltype, length

export IndexSupportPoint, IndexReturningArray, FlatIndexSupportPoint, FlatIndexReturningArray

struct IndexSupportPoint{N,V,I<:Tuple{Vararg{Number}}}
    val::V
    idx::I
    IndexSupportPoint(value::V, index::I) where {N, V, I<:NTuple{N, Number}} = new{N,V,I}(value, index)
    IndexSupportPoint{N}(value::V, index::I) where {N, V, I<:Tuple{Vararg{Number}}} = new{N,V,I}(value, index)
    IndexSupportPoint{N,V,I}(value::V, index::I) where {N, V, I<:Tuple{Vararg{Number}}} = new{N,V,I}(value, index)
end

@generated convert{N, V, IN, I<:NTuple{IN}}(::Type{IndexSupportPoint{N,V,I}}, val::Number) = :(IndexSupportPoint{$N, $V, $I}($V(val), $I(@ntuple $IN i->1)))

(+){ISP<:IndexSupportPoint}(As::Vararg{<:NTuple{M, ISP} where M, N} where N) = foldl((a,b) -> (a...,b...), As)#::Tuple{Vararg{ISP}}
(*){ISP<:IndexSupportPoint}(val, isps::Tuple{Vararg{ISP}}) = map(isp -> IndexSupportPoint(val*isp.val, isp.idx), isps)

struct IndexReturningArray{N, V, I<:NTuple{N, Integer}} <: AbstractArray{Tuple{IndexSupportPoint{N, V, I}},N}
    _size::I
    IndexReturningArray(::Type{V}, _size::I) where {N,V,I<:NTuple{N, Integer}} = new{N,V,I}(_size)
end
IndexReturningArray(_size::Tuple{Vararg{<:Integer}}) = IndexReturningArray(Float64, _size)
IndexReturningArray{T}(::Type{T}, _size::Vararg{<:Integer}) = IndexReturningArray(T, _size)
IndexReturningArray(_size::Vararg{<:Integer}) = IndexReturningArray(Float64, _size)

size(iar::IndexReturningArray) = iar._size
size(iar::IndexReturningArray, i::Int) = iar._size[i]

@inline getindex{N,V,I}(iar::IndexReturningArray{N,V,I}, idx::Vararg{Int, N}) = IndexSupportPoints((IndexSupportPoint(one(V), idx),))

struct FlatIndexSupportPoint{V,I<:Number}
    val::V
    idx::I
    FlatIndexSupportPoint(value::V, index::I) where {V, I<:Number} = new{V,I}(value, index)
end

convert{V, I}(::Type{FlatIndexSupportPoint{V,I}}, val::Number) = FlatIndexSupportPoint(V(val), one(I))

(+){ISP<:FlatIndexSupportPoint}(As::Vararg{<:NTuple{M, ISP} where M, N} where N) = foldl((a,b) -> (a...,b...), As)#::Tuple{Vararg{ISP}}
(*){ISP<:FlatIndexSupportPoint}(val, isps::Tuple{Vararg{ISP}}) = map(isp -> FlatIndexSupportPoint(val*isp.val, isp.idx), isps)

struct FlatIndexReturningArray{N, V, I<:NTuple{N, Integer}} <: AbstractArray{Tuple{FlatIndexSupportPoint{V, Int}},N}
    _size::I
    FlatIndexReturningArray(::Type{V}, _size::I) where {N,V,I<:NTuple{N, Integer}} = new{N,V,I}(_size)
end
FlatIndexReturningArray(_size::Tuple{Vararg{<:Integer}}) = FlatIndexReturningArray(Float64, _size)
FlatIndexReturningArray{T}(::Type{T}, _size::Vararg{<:Integer}) = FlatIndexReturningArray(T, _size)
FlatIndexReturningArray(_size::Vararg{<:Integer}) = FlatIndexReturningArray(Float64, _size)

size(fiar::FlatIndexReturningArray) = fiar._size
size(fiar::FlatIndexReturningArray, i::Int) = fiar._size[i]

@inline getindex{N,V,I}(fiar::FlatIndexReturningArray{N,V,I}, idx::Vararg{Int, N}) = (FlatIndexSupportPoint(one(V), sub2ind(fiar, idx...)),)
