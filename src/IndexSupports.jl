import Base: size, getindex, (*), (+)

export IndexSupportPoint, IndexReturningArray, FlatIndexReturningArray, assemble

struct IndexSupportPoint{N,V,I<:NTuple{N,Number}}
    val::V
    idx::I
    IndexSupportPoint(value::V, index::I) where {N, V, I<:NTuple{N, Number}} = new{N,V,I}(value, index)
end

struct IndexReturningArray{N, V} <: AbstractArray{IndexSupportPoint{N, V},N}
    _size::NTuple{N, Int}
    IndexReturningArray{V}(_size::NTuple{N, Int}) where {N,V} = new{N,V}(_size)
    IndexReturningArray(_size::NTuple{N, Int}) where N = new{N,Float64}(_size)
end

size(iar::IndexReturningArray) = iar._size
size(iar::IndexReturningArray, i::Int) = iar._size[i]

getindex{N,V}(iar::IndexReturningArray{N,V}, idx::Vararg{Int, N}) = (IndexSupportPoint(one(V), idx),)

struct FlatIndexReturningArray{N, V} <: AbstractArray{IndexSupportPoint{N, V},N}
    _size::NTuple{N, Int}
    FlatIndexReturningArray{V}(_size::NTuple{N, Int}) where {N,V} = new{N,V}(_size)
    FlatIndexReturningArray(_size::NTuple{N, Int}) where N = new{N,Float64}(_size)
end

size(fiar::FlatIndexReturningArray) = fiar._size
size(fiar::FlatIndexReturningArray, i::Int) = fiar._size[i]

getindex{N,V}(iar::IndexReturningArray{N,V}, idx::Vararg{Int, N}) = (IndexSupportPoint(one(V), idx),)

getindex{N,V}(fiar::FlatIndexReturningArray{N,V}, idx::Vararg{Int, N}) = (IndexSupportPoint(one(V), (sub2ind(fiar, idx...),)),)

(*){NT}(val, isps::NTuple{NT, IndexSupportPoint}) = map(isp -> IndexSupportPoint(val*isp.val, isp.idx), isps)
(+){N,V,I, NT1, NT2}(isps1::NTuple{NT1, IndexSupportPoint{N,V,I}}, isps2::NTuple{NT2, IndexSupportPoint{N,V,I}}) = (isps1..., isps2...)

assemble{NT,N}(isps::NTuple{NT, IndexSupportPoint{N}}) = ([isp.val for isp in isps], ([isp.idx[i] for isp in isps] for i in 1:N)...)
