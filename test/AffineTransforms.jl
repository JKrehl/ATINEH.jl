using Base.Test

@testset "AffineTransform typedefs" begin
    @test AffineTransform{3, StaticArrays.SMatrix{3,3,Int,9}, StaticArrays.SVector{3, Int}} <: AffineTransform
    @test isa(AffineTransform{3}(), AffineTransform{3})
end
