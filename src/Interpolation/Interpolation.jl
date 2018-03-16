
export AbstractInterpolation,
    AbstractLatticeInterpolation

abstract type AbstractInterpolation <: AbstractIndexingModifier end

@implupdate AbstractInterpolation transform x v::AffineTransform -> x

include("LatticeInterpolation.jl")
include("LinearInterpolation.jl")
include("NearestInterpolation.jl")
