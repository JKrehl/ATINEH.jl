import Base: getindex, setindex!

export ConstantExterior

struct ConstantExterior{N, T} <: AbstractIndexTransform{N}
    value::T
    ConstantExterior{N}(value::T=0) where {N,T} = new{N,T}(value)
    ConstantExterior{N, T}() where {N,T} = new{N,T}(zero(T))
end

@inline function getindex{N, T, I<:NTuple{N,Number}}(A::AbstractArray{T, N}, itc::IndexTransformChain{N}, ce::ConstantExterior{N}, idx::I)
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return T(ce.value); end
    @inbounds return getindex(A, itc, idx...)
end

@inline function setindex!{N, I<:NTuple{N,Number}}(A::AbstractArray{T,N} where T, val, itc::IndexTransformChain{N}, ce::ConstantExterior{N}, idx::I)
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds setindex!(A, val, itc, idx...)
end

@inline function addindex!{N, I<:NTuple{N,Number}}(A::AbstractArray{T,N} where T, val, itc::IndexTransformChain{N}, ce::ConstantExterior{N}, idx::I)
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds addindex!(A, val, itc, idx...)
end
