import Base: getindex, setindex!
import ATINEH: addindex!

export IndexAffineTransform

struct IndexAffineTransform{AT<:AffineTransform} <: AbstractIndexMap
    at::AT
end

@inline function getindex(A::AbstractArray, iat::IndexAffineTransform, idx::Vararg{<:Number})
    getindex(A, (iat.at*idx)...)
end

@inline function setindex!(A::AbstractArray, val, iat::IndexAffineTransform, idx::Vararg{<:Number})
    setindex!(A, val, (iat.at*idx)...)
end

@inline function addindex!(A::AbstractArray, val, iat::IndexAffineTransform, idx::Vararg{<:Number})
    addindex!(A, val, (iat.at*idx)...)
end
