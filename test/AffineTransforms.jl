using Base.Test

using StaticArrays

@testset "AffineTransform" begin
    @testset "constructors" begin
        @test AffineTransform{3, StaticArrays.SMatrix{3,3,Float64,9}, StaticArrays.SVector{3, Int}} <: AffineTransform{3}
        @test isa(@inferred(AffineTransform(ones(SMatrix{3,3,Int}), zeros(SVector{3,Int}))), AffineTransform{3, SMatrix{3,3,Int,9}, SVector{3,Int}})
        @test isa(@inferred(AffineTransform{2}()), AffineTransform{2, SMatrix{2,2,Float64,4}, SVector{2,Float64}})
        @test isa(@inferred(AffineTransform{4}(eye(SMatrix{4,4,Float64}))), AffineTransform{4})
        @test @inferred(AffineTransform(eye(SMatrix{3,3}))) == AffineTransform(eye(SMatrix{3,3}), zeros(SVector{3,Float64}))
        @test @inferred(AffineTransform{3}(eye(3), zeros(3))) == AffineTransform(eye(SMatrix{3,3}), zeros(SVector{3}))
        @test @inferred(AffineTransform(Val{3}, eye(3), zeros(3))) == AffineTransform(eye(SMatrix{3,3}), zeros(SVector{3}))
        @test @inferred(AffineTransform(Val{3})) == AffineTransform{3}()
    end

    @testset "elementary functions" begin
        @test @inferred(size(AffineTransform{3}())) == 3
        @test @inferred(size(AffineTransform{3})) == 3
        @test eltype(AffineTransform(eye(SMatrix{3,3,Float32}))) == Float32
        @test eltype(AffineTransform(eye(SMatrix{3,3,Int8}))) == Int8
        @test show(IOBuffer(), AffineTransform{3}()) == nothing
    end

    @testset "mathematical functions" begin
        @test @inferred(inv(AffineTransform{3}())) == AffineTransform{3}()
        @test @inferred(inv(inv(AffineTransform(SMatrix{2,2}(Diagonal([2.,2.])))))) == AffineTransform(SMatrix{2,2}(Diagonal([2.,2.])))
        @test @inferred(AffineTransform(SMatrix{2,2}(Diagonal([2.,2.])))*AffineTransform(SMatrix{2,2}(Diagonal([2,2])))) == AffineTransform(SMatrix{2,2}(Diagonal([4.,4.])))
        @test @inferred(*(AffineTransform(SMatrix{3,3}(Diagonal([2.,2.,1.]))), [4,5,6])) == Float64[8.,10.,6.]
        @test begin a=ones(3); @inferred(A_mul_B!(a, AffineTransform(SMatrix{3,3}(Diagonal([2.,2.,1.]))), [4,5,6])); a == Float64[8.,10.,6.]; end
        @test @inferred(SMatrix{3,3}(Diagonal([0,2,1])) * (1,2.,3)) == (0.0, 4.0, 3.0)
        @test @inferred(+(SVector{5}([1,2,3,4,5]), (1.,1,1.,1,1.))) == (2.0, 3, 4.0, 5, 6.0)
        @inferred(AffineTransform(SMatrix{2,2}(Diagonal([2.,2.])))*(1.,1)) == (2.,2.)
    end

    @testset "convenient constructors" begin
        @test @inferred(axisrotate((1,0,0), 0)) == AffineTransform{3}()
        @test isapprox(@inferred(axisrotate((1,0,0), pi)).matrix, AffineTransform(SMatrix{3,3,Float64}([1,0,0,0,-1,0,0,0,-1])).matrix)
    end
end
