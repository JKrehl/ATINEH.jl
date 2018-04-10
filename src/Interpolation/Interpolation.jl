
export AbstractInterpolation

abstract type AbstractInterpolation <: AbstractIndexingModifier end

@implupdate AbstractInterpolation transform x v::AffineTransform -> x

include("LinearInterpolation.jl")
include("NearestInterpolation.jl")
