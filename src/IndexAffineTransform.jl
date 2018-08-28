import LinearAlgebra: getindex, setindex!
import ATINEH: addindex!

export IndexAffineTransform

struct IndexAffineTransform{N, AT<:AffineTransform{N}} <: AbstractIndexingModifier
    transform::AT
    IndexAffineTransform(transform::AT) where {N, AT<:AffineTransform{N}} = new{N,AT}(transform)
end

@propagate_inbounds function getindex(A::MappedArray_byMap{<:IndexAffineTransform{N}}, idx::Vararg{<:Number, N}) where N
    getindex(A.array, (A.map.transform*idx)...)
end


@propagate_inbounds function setindex!(A::MappedArray_byMap{<:IndexAffineTransform{N}}, val, idx::Vararg{<:Number, N}) where N
    setindex!(A.array, val, (A.map.transform*idx)...)
end

@propagate_inbounds function addindex!(A::MappedArray_byMap{<:IndexAffineTransform{N}}, val, idx::Vararg{<:Number, N}) where N
    addindex!(A.array, val, (A.map.transform*idx)...)
end
