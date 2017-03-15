using StaticArrays

export AffineTransform

struct AffineTransform{N, MT<:SMatrix{N,N}, ST<:SVector{N}}
    matrix::MT
    shift::ST
    AffineTransform{N}(matrix::MT=eye(SMatrix{N,N, Int}), shift::ST=zeros(SVector{N,Int})) where {N, MT<:SMatrix{N,N}, ST<:SVector{N}} = new{N,MT,ST}(matrix,shift)
end
