import Base: getindex, setindex!
import ATINEH:NAbstractArray, addindex!

export NearestInterpolation

struct NearestInterpolation{N} <: AbstractIndexTransform{N}
end

@inline function getindex{N}(A::NAbstractArray{N}, imc::IndexTransformChain{N}, ::NearestInterpolation{N}, I::IT where IT<:NTuple{N,Number})
    getindex(A, imc, map(x -> round(Int, x), I)...)
end

@generated function setindex!{N}(A::NAbstractArray{N}, val, imc::IndexTransformChain{N}, ::NearestInterpolation{N}, I::IT where IT<:NTuple{N,Number})
    setindex!(A, val, imc, map(x -> round(Int, x), I)...)
end

@generated function addindex!{N}(A::NAbstractArray{N}, val, imc::IndexTransformChain{N}, ::NearestInterpolation{N}, I::IT where IT<:NTuple{N,Number})
    addindex!(A, val, imc, map(x -> round(Int, x), I)...)
end
