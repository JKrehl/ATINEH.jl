using Base.Test

@testset "IndexTransform" begin
   @testset "IndexIdentity" begin
        @test @inferred(IndexIdentity()) isa AbstractIndexingModifier
    end

    @testset "IndexMapChain" begin
        @test @inferred(IndexMapChain()) isa AbstractIndexingModifier
        @test @inferred(IndexMapChain(IndexIdentity())) isa IndexMapChain{Tuple{IndexIdentity}}
        @test @inferred(IndexIdentity() ∘ IndexIdentity()) isa IndexMapChain
        @test @inferred(IndexIdentity() ∘ IndexIdentity() ∘ IndexIdentity()) isa IndexMapChain
        @test @inferred(IndexIdentity() ∘ (IndexIdentity() ∘ IndexIdentity())) isa IndexMapChain
        @test @inferred(IndexIdentity() ∘ IndexIdentity() ∘ (IndexIdentity() ∘ IndexIdentity())) isa IndexMapChain
    end


    @testset "getindex usecases" begin
        @test let A = rand((12, 12));
            @inferred(A[IndexIdentity(), 3, 2]) == A[3, 2];
        end
        @test let A = rand((13, 12));
            @inferred(A[IndexMapChain(IndexIdentity()), 17]) == A[17];
        end
        @test let A = rand((12, 13, 12));
            @inferred(A[IndexIdentity(), IndexIdentity(), 3, 7, 2]) == A[3, 7, 2];
        end
    end

    @testset "setindex! usecases" begin
        @test let A = rand((12, 12))
            setindex!(A, 1, IndexIdentity(), 3, 2)
            A[3, 2] == 1
        end
        @test let A = rand((13, 12));
            setindex!(A, 3., IndexMapChain(IndexIdentity()), 17)
            A[17] == 3.
        end
        @test let A = rand((12, 12, 12))
            setindex!(A, 2, IndexIdentity(), IndexIdentity(), 3, 7, 2)
            A[3, 7, 2] == 2
        end
    end

    @testset "addindex! usecases" begin
        @test let A = collect(reshape(1:12^2, (12,12)))
            addindex!(A, 1, IndexIdentity(IndexIdentity()), 3, 2)
            A[3, 2] == 16
        end
        @test let A = collect(reshape(1:12^2, (12, 12)))
            addindex!(A, 12, IndexMapChain(IndexIdentity()), 17)
            A[17] == 29
        end
        @test let A = collect(reshape(1:12^3, (12, 12, 12)))
            addindex!(A, 2, IndexIdentity(), IndexIdentity(), 3, 7, 2)
            A[3, 7, 2] == 221
        end
    end
end
