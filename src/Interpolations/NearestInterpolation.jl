import Base: getindex, setindex!, round
import ATINEH:addindex!

export NearestInterpolation

round(x::Real, ::RoundingMode{:Nearest}) = trunc(x)
round{I<:Integer}(::Type{I}, x::Integer, ::RoundingMode) = I(x)


struct NearestInterpolation{R<:RoundingMode} <: AbstractIndexMap
    NearestInterpolation(::R=RoundNearest) where {R<:RoundingMode} = new{R}()
end

@inline function getindex{R}(A::MappedArray_byMap{<:NearestInterpolation{R}}, I::Vararg{<:Number})
    getindex(A.a, map(x -> round(Int, x, R()), I)...)
end

@inline function setindex!{R}(A::MappedArray_byMap{<:NearestInterpolation{R}}, val, I::Vararg{<:Number})
    setindex!(A.a, val, map(x -> round(Int, x, R()), I)...)
end

@inline function addindex!{R}(A::MappedArray_byMap{<:NearestInterpolation{R}}, val, I::Vararg{<:Number})
    addindex!(A.a, val, map(x -> round(Int, x, R()), I)...)
end
