import Base: (*), (+), size, getindex, eltype, one
export IndexSupport, FlatIndexSupport, AbstractSupportReturningArray, SupportReturningArray

abstract type AbstractIndexSupport{N,V,I} end

struct IndexSupport{N,V,I<:NTuple{N, Number}} <: AbstractIndexSupport{N,V,I}
    val::V
    idx::I
    IndexSupport(val::V, idx::I) where {N,V,I<:NTuple{N, <:Number}} = new{N,V,I}(val, idx)
    IndexSupport{N,V,I}(val, idx=ntuple(_->1, Val{N}())) where {N,V,I<:NTuple{N, <:Number}} = new{N,V,I}(V(val), I(idx))
end
@inline (*)(val::V, isp::IS) where {IS<:IndexSupport, V<:Number} = IndexSupport(val*isp.val, isp.idx)

struct FlatIndexSupport{N,V,I<:Number} <: AbstractIndexSupport{N,V,I}
    val::V
    idx::I
    FlatIndexSupport(::Val{N}, val::V, idx::I) where {N,V,I<:Number} = new{N,V,I}(val, idx)
    FlatIndexSupport{N,V,I}(val, idx=1) where {N,V,I} = new{N,V,I}(V(val), I(idx))
end
@inline one(::Type{F}) where {T, F<:FlatIndexSupport{N,T} where N} = one(T)

@inline (*)(val::V, isp::IS) where {N, IS<:FlatIndexSupport{N}, V<:Number}= FlatIndexSupport(Val{N}(), val*isp.val, isp.idx)

@inline (+)(a::Vararg{IS}) where {IS<:AbstractIndexSupport} = a
@inline (+)(a::A, b::B) where {IS<:AbstractIndexSupport, A<:NTuple{N, IS} where N, B<:NTuple{N, IS} where N} = (a..., b...)
@inline (+)(a::A, b::IS) where {IS<:AbstractIndexSupport, A<:NTuple{N, IS} where N} = (a..., b)
@inline (+)(a::IS, b::B) where {IS<:AbstractIndexSupport, B<:NTuple{N, IS} where N} = (a, b...)
@inline (*)(val::V, isps::NTuple{NIS, IS}) where {V<:Number, IS<:AbstractIndexSupport, NIS} = map(i->val*i, isps)

abstract type AbstractSupportReturningArray{N, IS<:AbstractIndexSupport{N}} <: AbstractArray{IS,N} end

@inline size(iar::A where A<:AbstractSupportReturningArray) = iar._size
@inline size(iar::A where A<:AbstractSupportReturningArray, i::Int) = iar._size[i]
@inline eltype(::A where {N, A<:AbstractSupportReturningArray{N, IS}}) where IS = IS
@inline eltype(::Type{A} where {N, A<:AbstractSupportReturningArray{N, IS}}) where IS = IS

struct SupportReturningArray{N, IS<:AbstractIndexSupport{N}} <: AbstractSupportReturningArray{N, IS}
    _size::NTuple{N, Int}
    SupportReturningArray(::Type{IS}, _size::NTuple{N,<:Integer}) where {N, IS<:AbstractIndexSupport{N}} = new{N,IS}(NTuple{N,Int}(_size))
end

SupportReturningArray(::Type{IndexSupport}, ::Type{V}, _size::NTuple{N,<:Integer}) where {N, V} = SupportReturningArray(IndexSupport{N,V,NTuple{N,Int}}, _size)
SupportReturningArray(::Type{IndexSupport}, _size::NTuple{N,<:Integer}) where N = SupportReturningArray(IndexSupport{N,Float64,NTuple{N,Int}}, _size)

SupportReturningArray(::Type{FlatIndexSupport}, ::Type{V}, _size::NTuple{N,<:Integer}) where {N, V} = SupportReturningArray(FlatIndexSupport{N,V,Int}, _size)
SupportReturningArray(::Type{FlatIndexSupport}, _size::NTuple{N,<:Integer}) where N = SupportReturningArray(FlatIndexSupport{N,Float64,Int}, _size)

SupportReturningArray(::Type{T}, x...) where T = SupportReturningArray(T, x)
SupportReturningArray(::Type{T}, ::Type{V}, x...) where {T,V} = SupportReturningArray(T, V, x)

@propagate_inbounds getindex(_::SupportReturningArray{N,IS}, idx::Vararg{<:Integer, N}) where {N,V,I,IS<:IndexSupport{N,V,I}} = IS(one(V), I(idx))
@propagate_inbounds getindex(iar::SupportReturningArray{N,IS}, idx::Vararg{<:Integer, N}) where {N,V,I,IS<:FlatIndexSupport{N,V,I}} = IS(one(V), I(LinearIndices(iar._size)[idx...,]))
