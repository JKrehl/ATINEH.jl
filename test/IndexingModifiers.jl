using Test

@testset "IndexTransform" begin
    @testset "IndexIdentity" begin
        @test @inferred(IndexIdentity()) isa AbstractIndexingModifier
    end
    
    @testset "getindex usecases" begin
        @test let A = rand(Float64, (12, 12));
            @inferred(A[IndexIdentity(), 3, 2]) == A[3, 2];
        end
        @test let A = rand(Float64, (12, 13, 12));
            @inferred(A[IndexIdentity(), IndexIdentity(), 3, 7, 2]) == A[3, 7, 2];
        end
    end

    @testset "setindex! usecases" begin
        @test let A = rand(Float64, (12, 12))
            setindex!(A, 1, IndexIdentity(), 3, 2)
            A[3, 2] == 1
        end
        @test let A = rand(Float64, (12, 12, 12))
            setindex!(A, 2, IndexIdentity(), IndexIdentity(), 3, 7, 2)
            A[3, 7, 2] == 2
        end
    end

    @testset "addindex! usecases" begin
        @test let A = collect(reshape(1:12^2, (12,12)))
            addindex!(A, 1, IndexIdentity(IndexIdentity()), 3, 2)
            A[3, 2] == 16
        end
        @test let A = collect(reshape(1:12^3, (12, 12, 12)))
            addindex!(A, 2, IndexIdentity(), IndexIdentity(), 3, 7, 2)
            A[3, 7, 2] == 221
        end
    end
end
