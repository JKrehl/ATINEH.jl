import Base: getindex, setindex!
import ATINEH: addindex!

export IndexAffineTransform

    trafo::AT
struct IndexAffineTransform{N, AT<:AffineTransform{N}} <: AbstractIndexingModifier
end

    getindex(A.a, (A.m.trafo*idx)...)
@propagate_inbounds function getindex(A::MappedArray_byMap{<:IndexAffineTransform{N}}, idx::Vararg{<:Number, N}) where N
end

    setindex!(A.a, val, (A.m.trafo*idx)...)
@propagate_inbounds function setindex!(A::MappedArray_byMap{<:IndexAffineTransform{N}}, val, idx::Vararg{<:Number, N}) where N
end

    addindex!(A.a, val, (A.m.trafo*idx)...)
@propagate_inbounds function addindex!(A::MappedArray_byMap{<:IndexAffineTransform{N}}, val, idx::Vararg{<:Number, N}) where N
end
