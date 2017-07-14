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
    if checkbounds(Bool, A, map(floor, idx)...)
        @inbounds re = getindex(A.a, idx...)
        re
    else
        T(A.m.value)
    end
end

@inline function setindex!{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, val, idx::Vararg{<:Number})
    if checkbounds(Bool, A, map(floor, idx)...)
        @inbounds setindex!(A.a, val, idx...)
    end
end

@inline function addindex!{T}(A::MappedArray{T, N, A, <:ConstantExterior} where {N,A}, val, idx::Vararg{<:Number})
    if checkbounds(Bool, A, map(floor, idx)...)
        @inbounds addindex!(A.a, val, idx...)
    end
end

struct InBounds <: AbstractIndexingModifier end

@inline function getindex{T}(A::MappedArray{T, N, A, <:InBounds} where {N,A}, idx::Vararg{<:Number})
    @inbounds getindex(A.a, idx...)
end

@inline function setindex!{T}(A::MappedArray{T, N, A, <:InBounds} where {N,A}, val, idx::Vararg{<:Number})
    @inbounds setindex!(A.a, val, idx...)
end

@inline function addindex!{T}(A::MappedArray{T, N, A, <:InBounds} where {N,A}, val, idx::Vararg{<:Number})
    @inbounds addindex!(A.a, val, idx...)
end
