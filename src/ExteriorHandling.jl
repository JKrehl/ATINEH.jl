import Base: getindex, setindex!

export ConstantExterior


"conversion for numerical element types with special rule for Tuple{...} types"
@inline elconvert{T}(::Type{T}, x) = T(x)

@generated function elconvert{T<:Tuple}(::Type{T}, x)
    Expr(:block, Expr(:meta, :inline), Expr(:tuple, (:($t(x)) for t in T.types)...))
end

struct ConstantExterior{T} <: AbstractIndexMap
    value::T
    ConstantExterior(value::T=0) where {T} = new{T}(value)
    ConstantExterior{T}() where {T} = new{T}(zero(T))
end

@inline function getindex{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return T(A.m.value); end
    @inbounds return getindex(A.a, idx...)
end

@inline function setindex!{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, val, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds setindex!(A.a, val, idx...)
end

@inline function addindex!{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, val, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds addindex!(A.a, val, idx...)
end
