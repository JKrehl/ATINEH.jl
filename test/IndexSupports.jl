using Base.Test

@testset "IndexSupport" begin
    @test @inferred(SupportReturningArray(IndexSupport, (3,4,5))) isa AbstractArray{IndexSupport{3,Float64,Tuple{Int64,Int64,Int64}}, 3}
    @test @inferred(SupportReturningArray(IndexSupport, (3,4,5))[1,1,1]) == IndexSupport(1.0, (1, 1, 1))
    @test size(SupportReturningArray(IndexSupport, (3,4,5)), 1) == 3
    @test size(SupportReturningArray(IndexSupport, (3,4,5))) == (3,4,5)
    @test @inferred(SupportReturningArray(IndexSupport, Float64, (3,4,5))[ConstantExterior(), 1,1,1]) == IndexSupport(1.0, (1, 1, 1))
    @test SupportReturningArray(IndexSupport, (3,4,5))[ConstantExterior(), -1,1,1] == IndexSupport{3,Float64,Tuple{Int64,Int64,Int64}}(0)
    @test SupportReturningArray(FlatIndexSupport, (3,4,5))[ConstantExterior(), 2,2,2] == FlatIndexSupport(Val{3}, 1.0, 17)
    @test SupportReturningArray(FlatIndexSupport, (3,4,5))[ConstantExterior(), -2,2,2] == FlatIndexSupport{3,Float64,Int64}(0)
    @test @inferred(SupportReturningArray(FlatIndexSupport, (3,4,5))[LinearInterpolation(), 1.2,1.3,1]) isa NTuple{4, FlatIndexSupport{3,Float64,Int64}}
    @test eltype(SupportReturningArray(IndexSupport, Float32, (3,4,5))) == IndexSupport{3, Float32, Tuple{Int, Int, Int}}
    @test eltype(typeof(SupportReturningArray(FlatIndexSupport, 3,4,5))) == FlatIndexSupport{3, Float64, Int}
    @test eltype(typeof(SupportReturningArray(FlatIndexSupport, Float32, 3,4,5))) == FlatIndexSupport{3, Float32, Int}
    @test 2*IndexSupport(1., (1,)) + (IndexSupport(1., (1,)) + IndexSupport(1., (1,))) == (2*IndexSupport(1., (1,)) + IndexSupport(1., (1,))) + IndexSupport(1., (1,))
end
