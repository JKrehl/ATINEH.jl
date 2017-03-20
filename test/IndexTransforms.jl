using Base.Test

@testset "IndexTransform" begin
   @testset "constructors" begin
        @test isa(@inferred(IndexIdentity{3}()), AbstractIndexTransform)
        @test @inferred(IndexTransformChain{3}()) == IndexTransformChain{3}(())
        @test isa(@inferred(IndexTransformChain((IndexIdentity{4}(),))), IndexTransformChain{4})
    end
    @testset "chaining" begin
        @test isa(@inferred(IndexIdentity{3}() ∘ IndexIdentity{3}()), IndexTransformChain{3,Tuple{IndexIdentity{3},IndexIdentity{3}}})
        @test isa(@inferred(IndexTransformChain{3}() ∘ IndexIdentity{3}()), IndexTransformChain{3,Tuple{IndexIdentity{3}}})
        @test isa(@inferred(IndexIdentity{3}() ∘ IndexTransformChain{3}((IndexIdentity{3}(),))), IndexTransformChain{3,Tuple{IndexIdentity{3},IndexIdentity{3}}})
        @test @inferred(IndexTransformChain{1}((IndexIdentity{1}(),)) ∘ IndexTransformChain{1}((IndexIdentity{1}(),))).transforms == (IndexIdentity{1}(), IndexIdentity{1}())
    end
    @testset "getindex dispatch" begin
        @test @inferred(ATINEH.rhead((7,"1",cos,2))) == 2
        @test @inferred(ATINEH.rtail((7,"1",cos,2))) == (7,"1",cos)
    end
    @testset "usecases" begin
        A = rand((5,5,5))
        @test A[1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexTransformChain{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}() ∘ IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}(), IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
        @test A[IndexIdentity{3}(), IndexIdentity{3}() ∘ IndexIdentity{3}(), 1,2,3] == getindex(A, 1, 2, 3)
    end
end
