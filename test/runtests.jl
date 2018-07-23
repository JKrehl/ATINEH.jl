using ATINEH
using Test

@testset "runtests" begin
    include("AffineTransforms.jl")
    include("IndexingModifiers.jl")
    include("ExteriorHandling.jl")
    @testset "Interpolations" begin
        include("Interpolations/LinearInterpolation.jl")
        include("Interpolations/NearestInterpolation.jl")
    end
    include("IndexAffineTransform.jl")
    include("IndexSupports.jl")
end
