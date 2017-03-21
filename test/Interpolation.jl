using Base.Test

@testset "Interpolation" begin
    @testset "LinearInterpolation" begin
        A = reshape(collect(1:16),4,4)
        @test @inferred(getindex(A, LinearInterpolation{2}(), 2.5, 2)) == 6.5
        @test @inferred(getindex(A, LinearInterpolation{2}(), 2.5, 2.5)) == 8.5
        @test_throws ArgumentError setindex!(A, 2., LinearInterpolation{2}(), 2.25, 2.5)
        @test let B=Matrix{Float64}(A); @inferred(addindex!(B, 1., LinearInterpolation{2}(), 2.25, 2.5)); sum(B) == sum(A)+1. end
        @test let B=Matrix{Float64}(A); @inferred(addindex!(B, 1., LinearInterpolation{2}(), 2.25, 2)); sum(B) == sum(A)+1. end
    end
end
