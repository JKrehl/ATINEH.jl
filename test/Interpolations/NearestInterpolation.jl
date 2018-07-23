using Test

@testset "Interpolation" begin
    @testset "NearestInterpolation" begin
        A = reshape(collect(1:16),4,4)
        @test @inferred(getindex(A, NearestInterpolation(), 2.5, 2)) == 6
        @test let B=copy(A); setindex!(B, -3, NearestInterpolation(), 2.5, 2); B[2,2] == -3; end
        @test let B=copy(A); addindex!(B, -3, NearestInterpolation(), 2, 2.5); B[2,2] == 3; end
    end
end
