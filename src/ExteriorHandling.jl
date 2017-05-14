import Base: getindex, setindex!

export ConstantExterior

struct ConstantExterior{T} <: AbstractIndexMap
    value::T
    ConstantExterior(value::T=0) where {T} = new{T}(value)
    ConstantExterior{T}() where {T} = new{T}(zero(T))
end

@inline function getindex{T}(A::AbstractArray{T}, ce::ConstantExterior, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return T(ce.value); end
    @inbounds return getindex(A, idx...)
end

@inline function setindex!{T}(A::AbstractArray{T}, val, ce::ConstantExterior, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds setindex!(A, val, idx...)
end

@inline function addindex!{T}(A::AbstractArray{T}, val, ce::ConstantExterior, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds addindex!(A, val, idx...)
end
