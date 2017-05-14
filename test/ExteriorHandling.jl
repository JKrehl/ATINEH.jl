using Base.Test

@testset "Exterior Handling" begin
    @testset "ConstantExterior" begin
        A = rand(Int, (5,5,5))
        @test @inferred(A[ConstantExterior(), 1,1,1]) == A[1,1,1]
        @test @inferred(A[ConstantExterior(), -1,1,1]) == zero(Int)
        @test @inferred(A[ConstantExterior(1), -1,1,1]) == one(Int)
        B = copy(A)
        B[2,4,2] = 7
        @test let C=copy(A); @inferred(setindex!(C, 7, ConstantExterior(1), 2,4,2)); C==B end
        @test let C=copy(A); @inferred(setindex!(C, 7, ConstantExterior(1), -2,4,2)); C==A end
        B = copy(A)
        B[2,4,2] += 7
        @test let C=copy(A); @inferred(addindex!(C, 7, ConstantExterior(1), 2,4,2)); C==B end
        @test let C=copy(A); @inferred(addindex!(C, 7, ConstantExterior(1), -2,4,2)); C==A end
    end
end
