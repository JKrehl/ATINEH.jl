using Base.Test

@testset "IndexAffineTransform" begin
    @test @inferred(IndexAffineTransform(axisrotate((1,0,0),.01))) isa IndexAffineTransform{ATINEH.AffineTransform{3,StaticArrays.SMatrix{3,3,Float64,9},StaticArrays.SVector{3,Float64}}}
    @test @inferred(ones((5,5,5))[LinearInterpolation(), IndexAffineTransform(axisrotate((1,0,0),.01)), 2,2,2]) == 1.
    @test sum(@inferred(setindex!(ones(Int, (5,5,5)), 3, IndexAffineTransform(AffineTransform(eye(StaticArrays.SMatrix{3,3,Int}), zeros(StaticArrays.SVector{3,Int}))), 2, 2, 2))) == 127
    @test @inferred(addindex!(rand((5,5,5)), 1, LinearInterpolation(), IndexAffineTransform(axisrotate((1,0,0),.01)), 2,2,2)) == nothing
end
