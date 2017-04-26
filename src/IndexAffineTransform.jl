import Base: getindex, setindex!
import ATINEH: addindex!

export IndexAffineTransform

struct IndexAffineTransform{N, AT<:AffineTransform{N}} <: AbstractIndexTransform{N}
    at::AT
    IndexAffineTransform(at::AT) where {N, AT<:AffineTransform{N}} = new{N,AT}(at)
    IndexAffineTransform{N}(at::AT) where {N, AT<:AffineTransform{N}} = new{N,AT}(at)
end

@inline function getindex{N, T, I<:NTuple{N,Number}}(A::AbstractArray{T, N}, itc::IndexTransformChain{N}, iat::IndexAffineTransform{N}, idx::I)
    getindex(A, itc, (iat.at*idx)...)
end

@inline function setindex!{N, T, I<:NTuple{N,Number}}(A::AbstractArray{T, N}, val, itc::IndexTransformChain{N}, iat::IndexAffineTransform{N}, idx::I)
    setindex!(A, val, itc, (iat.at*idx)...)
end

@inline function addindex!{N, T, I<:NTuple{N,Number}}(A::AbstractArray{T, N}, val, itc::IndexTransformChain{N}, iat::IndexAffineTransform{N}, idx::I)
    addindex!(A, val, itc, (iat.at*idx)...)
end
