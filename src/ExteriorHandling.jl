import Base: getindex, setindex!

export ConstantExterior, InBounds


"conversion for numerical element types with special rule for Tuple{...} types"
@inline elconvert{T}(::Type{T}, x) = T(x)

@generated function elconvert{T<:Tuple}(::Type{T}, x)
    Expr(:block, Expr(:meta, :inline), Expr(:tuple, (:($t(x)) for t in T.types)...))
end

struct ConstantExterior{T} <: AbstractIndexingModifier
    value::T
    ConstantExterior(value::T=0) where {T} = new{T}(value)
    ConstantExterior{T}() where {T} = new{T}(zero(T))
end

@inline function getindex{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A.a, idx...); return T(A.m.value); end
    @inbounds re = getindex(A.a, idx...)
    re
end

@inline function setindex!{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, val, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A.a, idx...); return; end
    @inbounds setindex!(A.a, val, idx...)
end

@inline function addindex!{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, val, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A.a, idx...); return; end
    @inbounds addindex!(A.a, val, idx...)
end

struct InBounds <: AbstractIndexingModifier end

@inline function getindex{T}(A::MappedArray{T, N, A, <:InBounds} where {N,A}, idx::Vararg{<:Number})
    @inbounds re = getindex(A.a, idx...)
    re
end

@inline function setindex!{T}(A::MappedArray{T, N, A, <:InBounds} where {N,A}, val, idx::Vararg{<:Number})
    @inbounds re = setindex!(A.a, val, idx...)
    re
end

@inline function addindex!{T}(A::MappedArray{T, N, A, <:InBounds} where {N,A}, val, idx::Vararg{<:Number})
    @inbounds re = addindex!(A.a, val, idx...)
    re
end
