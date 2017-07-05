import Base: getindex, setindex!
import ATINEH: addindex!

export IndexAffineTransform

struct IndexAffineTransform{AT<:AffineTransform} <: AbstractIndexMap
    at::AT
end

@inline function getindex(A::MappedArray_byMap{<:IndexAffineTransform}, idx::Vararg{<:Number})
    getindex(A.a, (A.m.at*idx)...)
end

@inline function setindex!(A::MappedArray_byMap{<:IndexAffineTransform}, val, idx::Vararg{<:Number})
    setindex!(A.a, val, (A.m.at*idx)...)
end

@inline function addindex!(A::MappedArray_byMap{<:IndexAffineTransform}, val, idx::Vararg{<:Number})
    addindex!(A.a, val, (A.m.at*idx)...)
end
