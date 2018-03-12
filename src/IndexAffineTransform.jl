import Base: getindex, setindex!
import ATINEH: addindex!

export IndexAffineTransform

struct IndexAffineTransform{AT<:AffineTransform} <: AbstractIndexingModifier
    trafo::AT
end

@propagate_inbounds function getindex(A::MappedArray_byMap{<:IndexAffineTransform}, idx::Vararg{<:Number})
    getindex(A.a, (A.m.trafo*idx)...)
end

@propagate_inbounds function setindex!(A::MappedArray_byMap{<:IndexAffineTransform}, val, idx::Vararg{<:Number})
    setindex!(A.a, val, (A.m.trafo*idx)...)
end

@propagate_inbounds function addindex!(A::MappedArray_byMap{<:IndexAffineTransform}, val, idx::Vararg{<:Number})
    addindex!(A.a, val, (A.m.trafo*idx)...)
end
