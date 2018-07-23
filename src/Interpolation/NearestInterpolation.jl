import Base: getindex, setindex!, round
import ATINEH:addindex!

export NearestInterpolation

round(x::Real, ::RoundingMode{:Nearest}) = trunc(x)
round(::Type{I}, x::Integer, ::RoundingMode) where {I<:Integer} = I(x)


struct NearestInterpolation{R<:RoundingMode} <: AbstractInterpolation
    NearestInterpolation(::R=RoundNearest) where {R<:RoundingMode} = new{R}()
end

@propagate_inbounds function getindex(A::MappedArray_byMap{<:NearestInterpolation{R}}, I::Vararg{<:Number}) where {R}
    getindex(A.array, map(x -> round(Int, x, R()), I)...)
end

@propagate_inbounds function setindex!(A::MappedArray_byMap{<:NearestInterpolation{R}}, val, I::Vararg{<:Number}) where {R}
    setindex!(A.array, val, map(x -> round(Int, x, R()), I)...)
end

@propagate_inbounds function addindex!(A::MappedArray_byMap{<:NearestInterpolation{R}}, val, I::Vararg{<:Number}) where {R}
    addindex!(A.array, val, map(x -> round(Int, x, R()), I)...)
end
