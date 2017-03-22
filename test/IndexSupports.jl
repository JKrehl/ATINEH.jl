using Base.Test

@testset "IndexSupport" begin
    @test @inferred(IndexReturningArray((3,4,5))) isa AbstractArray{Vector{IndexSupportPoint{3,Float64, NTuple{3,Int}}},3}
    @test @inferred(IndexReturningArray((3,4,5))[1,1,1]) == [ATINEH.IndexSupportPoint(1.0, (1, 1, 1))]
    @test size(IndexReturningArray((3,4,5)), 1) == 3
    @test size(IndexReturningArray((3,4,5))) == (3,4,5)
    @test IndexReturningArray((3,4,5))[ConstantExterior{3}(), 1,1,1] == [ATINEH.IndexSupportPoint(1.0, (1, 1, 1)),]
    @test IndexReturningArray((3,4,5))[ConstantExterior{3}(), -1,1,1] == []
    @test size(FlatIndexReturningArray((3,4,5)), 1) == 3
    @test size(FlatIndexReturningArray((3,4,5))) == (3,4,5)
    @test FlatIndexReturningArray((3,4,5))[ConstantExterior{3}(), 2,2,2] == [ATINEH.IndexSupportPoint(1.0, (17,))]
    @test FlatIndexReturningArray((3,4,5))[ConstantExterior{3}(), -2,2,2] == ATINEH.IndexSupportPoint{3,Float64,NTuple{3,Int64}}[]
    @test @inferred(IndexReturningArray((3,4,5))[LinearInterpolation{3}(), 1.2,1.3,1]) isa Vector{ATINEH.IndexSupportPoint{3,Float64,NTuple{3,Int64}}}
    @test length(IndexReturningArray((3,4,5))[LinearInterpolation{3}(), 1.2,1.3,1]) == 4
    @test assemble(FlatIndexReturningArray((3,4,5))[LinearInterpolation{3}(), 1.2,1.3,1]) isa Tuple{Vector{Float64}, Vector{Int}}
end
