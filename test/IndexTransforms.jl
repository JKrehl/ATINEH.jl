using Base.Test

@testset "IndexTransform" begin
   @testset "constructors" begin
        @test @inferred(IndexIdentity{3}()) isa AbstractIndexTransform
        @test @inferred(IndexTransformChain{3}()) == IndexTransformChain{3}(())
        @test @inferred(IndexTransformChain((IndexIdentity{4}(),))) isa IndexTransformChain{4}
    end

    @testset "chaining" begin
        @test @inferred(IndexIdentity{3}() ∘ IndexIdentity{3}()) isa IndexTransformChain{3,Tuple{IndexIdentity{3},IndexIdentity{3}}}
        @test @inferred(IndexTransformChain{3}() ∘ IndexIdentity{3}()) isa IndexTransformChain{3,Tuple{IndexIdentity{3}}}
        @test @inferred(IndexIdentity{3}() ∘ IndexTransformChain{3}((IndexIdentity{3}(),))) isa IndexTransformChain{3,Tuple{IndexIdentity{3},IndexIdentity{3}}}
        @test @inferred(IndexTransformChain{1}((IndexIdentity{1}(),)) ∘ IndexTransformChain{1}((IndexIdentity{1}(),))).transforms == (IndexIdentity{1}(), IndexIdentity{1}())
    end

    @testset "helpers" begin
        @test @inferred(ATINEH.rhead((7,"1",cos,2))) == 2
        @test @inferred(ATINEH.rtail((7,"1",cos,2))) == (7,"1",cos)
    end

    @testset "getindex usecases" begin
        A = rand(Int, (5,5,5))
        @test A[IndexTransformChain{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}() ∘ IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}(), IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}(), IndexIdentity{3}() ∘ IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
    end

    @testset "setindex! usecases" begin
        A = rand(Int, (5,5,5))
        B = copy(A)
        B[3,4,1] = 1
        @test let C=copy(A); setindex!(C, 1, 3,4,1); C==B end
        @test let C=copy(A); setindex!(C, 1, IndexIdentity{3}(), 3,4,1); C==B end
        @test let C=copy(A); setindex!(C, 1, IndexIdentity{3}(), IndexIdentity{3}(), 3,4,1); C==B end
        @test let C=copy(A); setindex!(C, 1, IndexTransformChain{3}(), 3,4,1); C==B end
        @test let C=copy(A); setindex!(C, 1, IndexTransformChain{3}((IndexIdentity{3}(),)), IndexIdentity{3}(), 3,4,1); C==B end
    end

    @testset "addindex! usecases" begin
        A = rand(Int, (5,5,5))
        B = copy(A)
        B[1,2,3] += 1
        @test let C=copy(A); addindex!(C, 1, 1,2,3); C==B end
        @test let C=copy(A); addindex!(C, 1, IndexIdentity{3}(), 1,2,3); C==B end
        @test let C=copy(A); addindex!(C, 1, IndexIdentity{3}(), IndexIdentity{3}(), 1,2,3); C==B end
        @test let C=copy(A); addindex!(C, 1, IndexTransformChain{3}(), 1,2,3); C==B end
        @test let C=copy(A); addindex!(C, 1, IndexTransformChain{3}((IndexIdentity{3}(),)), IndexIdentity{3}(), 1,2,3); C==B end
    end
end
