using ATINEH
using Base.Test

@testset "runtests" begin
    include("AffineTransforms.jl")
    include("IndexTransforms.jl")
    include("ExteriorHandling.jl")
    include("Interpolation.jl")
    include("IndexAffineTransform.jl")
    include("IndexSupports.jl")
end
