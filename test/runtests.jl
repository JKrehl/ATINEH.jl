using ATINEH
using Base.Test

@testset "runtests" begin
    include("AffineTransforms.jl")
    include("IndexTransforms.jl")
    include("ExteriorHandling.jl")
    @testset "Interpolations" begin
        include("Interpolations/LinearInterpolation.jl")
    end
    include("IndexAffineTransform.jl")
    include("IndexSupports.jl")
end
