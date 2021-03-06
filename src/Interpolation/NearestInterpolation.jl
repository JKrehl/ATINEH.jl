import Base: getindex, setindex!, round
import ATINEH:addindex!

export NearestInterpolation

round(x::Real, ::RoundingMode{:Nearest}) = trunc(x)
round{I<:Integer}(::Type{I}, x::Integer, ::RoundingMode) = I(x)


struct NearestInterpolation{R<:RoundingMode} <: AbstractInterpolation
    NearestInterpolation(::R=RoundNearest) where {R<:RoundingMode} = new{R}()
end

@propagate_inbounds function getindex{R}(A::MappedArray_byMap{<:NearestInterpolation{R}}, I::Vararg{<:Number})
    getindex(A.array, map(x -> round(Int, x, R()), I)...)
end

@propagate_inbounds function setindex!{R}(A::MappedArray_byMap{<:NearestInterpolation{R}}, val, I::Vararg{<:Number})
    setindex!(A.array, val, map(x -> round(Int, x, R()), I)...)
end

@propagate_inbounds function addindex!{R}(A::MappedArray_byMap{<:NearestInterpolation{R}}, val, I::Vararg{<:Number})
    addindex!(A.array, val, map(x -> round(Int, x, R()), I)...)
end
