import Base: getindex, setindex!
import ATINEH: NAbstractArray

export ConstantExterior

struct ConstantExterior{N, T} <: AbstractIndexTransform{N}
    value::T
    ConstantExterior{N}(value::T=false) where {N,T} = new{N,T}(value)
    ConstantExterior{N, T}() where {N,T} = new{N,T}(zero(T))
end

@inline function getindex{N, T, I<:NTuple{N,Number}}(A::NAbstractArray{N, T}, itc::IndexTransformChain{N}, ce::ConstantExterior{N}, idx::I)
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return T(ce.value); end
    @inbounds return getindex(A, itc, idx...)
end

@inline function setindex!{N, I<:NTuple{N,Number}}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, ce::ConstantExterior{N}, idx::I)
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds setindex!(A, val, itc, idx...)
end

@inline function addindex!{N, I<:NTuple{N,Number}}(A::NAbstractArray{N}, val, itc::IndexTransformChain{N}, ce::ConstantExterior{N}, idx::I)
    @boundscheck if !checkbounds(Bool, A, map(floor, idx)...); return end
    @inbounds addindex!(A, val, itc, idx...)
end
