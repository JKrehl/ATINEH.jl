import Base: (*), (+), size, getindex, eltype
export IndexSupport, FlatIndexSupport, AbstractSupportReturningArray, SupportReturningArray

abstract type AbstractIndexSupport{N,V,I} end

struct IndexSupport{N,V,I<:NTuple{N, Number}} <: AbstractIndexSupport{N,V,I}
    val::V
    idx::I
    IndexSupport(val::V, idx::I) where {N,V,I<:NTuple{N, <:Number}} = new{N,V,I}(val, idx)
    IndexSupport{N,V,I}(val, idx=ntuple(_->1, Val{N})) where {N,V,I<:NTuple{N, <:Number}} = new{N,V,I}(V(val), I(idx))
end
@inline (*){IS<:IndexSupport, V<:Number}(val::V, isp::IS) = IndexSupport(val*isp.val, isp.idx)

struct FlatIndexSupport{N,V,I<:Number} <: AbstractIndexSupport{N,V,I}
    val::V
    idx::I
    FlatIndexSupport(::Type{Val{N}}, val::V, idx::I) where {N,V,I<:Number} = new{N,V,I}(val, idx)
    FlatIndexSupport{N,V,I}(val, idx=1) where {N,V,I} = new{N,V,I}(V(val), I(idx))
end
@inline (*){N, IS<:FlatIndexSupport{N}, V<:Number}(val::V, isp::IS) = FlatIndexSupport(Val{N}, val*isp.val, isp.idx)

@inline (+){IS<:AbstractIndexSupport}(a::Vararg{IS}) = a
@inline (+){IS<:AbstractIndexSupport, A<:NTuple{N, IS} where N, B<:NTuple{N, IS} where N}(a::A, b::B) = (a..., b...)
@inline (+){IS<:AbstractIndexSupport, A<:NTuple{N, IS} where N}(a::A, b::IS) = (a..., b)
@inline (+){IS<:AbstractIndexSupport, B<:NTuple{N, IS} where N}(a::IS, b::B) = (a, b...)
@inline (*){V<:Number, IS<:AbstractIndexSupport, NIS}(val::V, isps::NTuple{NIS, IS}) = map(i->val*i, isps)

abstract type AbstractSupportReturningArray{N, IS<:AbstractIndexSupport{N}} <: AbstractArray{IS,N} end

@inline size(iar::A where A<:AbstractSupportReturningArray) = iar._size
@inline size(iar::A where A<:AbstractSupportReturningArray, i::Int) = iar._size[i]
@inline eltype{IS}(::A where {N, A<:AbstractSupportReturningArray{N, IS}}) = IS
@inline eltype{IS}(::Type{A} where {N, A<:AbstractSupportReturningArray{N, IS}}) = IS

struct SupportReturningArray{N, IS<:AbstractIndexSupport{N}} <: AbstractSupportReturningArray{N, IS}
    _size::NTuple{N, Int}
    SupportReturningArray(::Type{IS}, _size::NTuple{N,<:Integer}) where {N, IS<:AbstractIndexSupport{N}} = new{N,IS}(NTuple{N,Int}(_size))
end

SupportReturningArray{N, V}(::Type{IndexSupport}, ::Type{V}, _size::NTuple{N,<:Integer}) = SupportReturningArray(IndexSupport{N,V,NTuple{N,Int}}, _size)
SupportReturningArray{N}(::Type{IndexSupport}, _size::NTuple{N,<:Integer}) = SupportReturningArray(IndexSupport{N,Float64,NTuple{N,Int}}, _size)

SupportReturningArray{N, V}(::Type{FlatIndexSupport}, ::Type{V}, _size::NTuple{N,<:Integer}) = SupportReturningArray(FlatIndexSupport{N,V,Int}, _size)
SupportReturningArray{N}(::Type{FlatIndexSupport}, _size::NTuple{N,<:Integer}) = SupportReturningArray(FlatIndexSupport{N,Float64,Int}, _size)

SupportReturningArray{T}(::Type{T}, x...) = SupportReturningArray(T, x)
SupportReturningArray{T,V}(::Type{T}, ::Type{V}, x...) = SupportReturningArray(T, V, x)

@propagate_inbounds getindex{N,V,I,IS<:IndexSupport{N,V,I}}(_::SupportReturningArray{N,IS}, idx::Vararg{<:Integer, N}) = IS(one(V), I(idx))
@propagate_inbounds getindex{N,V,I,IS<:FlatIndexSupport{N,V,I}}(iar::SupportReturningArray{N,IS}, idx::Vararg{<:Integer, N}) = IS(one(V), I(sub2ind(iar._size, idx...)))
