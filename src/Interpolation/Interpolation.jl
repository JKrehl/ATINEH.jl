
export AbstractInterpolation

abstract type AbstractInterpolation <: AbstractIndexingModifier end

update(ai::AbstractInterpolation, ::Val{:transform}, t) = ai

include("LinearInterpolation.jl")
include("NearestInterpolation.jl")
