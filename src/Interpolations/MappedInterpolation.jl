import Base: getindex, setindex!
import ATINEH:addindex!

using Base.Cartesian
using OffsetArrays

export MappedInterpolation, VolumetricInterpolation

struct MappedInterpolation{N, T, AT<:AbstractArray{<:AbstractArray{T,N},N}} <: AbstractIndexingModifier
    maps::AT
    offsets::NTuple{N, Int}
    MappedInterpolation(maps::AT, offsets::NTuple{N,Int}=ntuple(i->0, Val{N})) where {N, T, AT<:AbstractArray{<:AbstractArray{T,N},N}} = new{N, T, AT}(maps, offsets)
end

struct VolumetricInterpolation <: AbstractIndexingModifier
    S::Int
    D::Int
    VolumetricInterpolation(S::Int=32, D::Int=8) = new(S,D)
end

VolumetricInterpolation(trafo::AffineTransform, S::Int=32, D::Int=8) = MappedInterpolation(flatcube(trafo, S, D)...)

@inline subindex{I<:Integer}(a::I, s::Int) = one(I)

@inline function subindex{T<:Base.Math.IEEEFloat}(a::T, s::Int)
    us = reinterpret(Unsigned, a)
    e = ((us & Base.exponent_mask(T)) >>> Base.Math.significand_bits(T)) - (Base.Math.exponent_bias(T) - 32)
    b = (Base.significand_mask(T) & us)
    c = (b >>> (Base.Math.significand_bits(T)-e)) | (one(UInt) << e)
    d = copysign(c, a) & (zero(UInt32)-one(UInt32))
    reinterpret(Int, 1+((d*s) >>> 32))
end

import ATINEH: flatcube
@generated function flatcube{M,N,MT,ST}(trafo::AffineTransform{M,N,MT,ST}, S, D)
    T = promote_type(eltype(MT), eltype(ST), Bool)
    quote
        bins_max = @ntuple $M i -> ceil(Int, sum(abs, trafo.matrix[i,:]))
        bins_num = @ntuple $M i -> 1+2*bins_max[i]
        bins_idims = @ntuple $M i -> -bins_max[i]:bins_max[i]
        bins_dims = @ntuple $M i -> (-bins_max[i]):1/D:(bins_max[i])
        bins_offs = @ntuple $M i -> bins_max[i]*D+1
        Dtrafo = unscale(bins_dims...)*AffineTransform(trafo.matrix)

        bins = zeros($T, map(length, bins_dims))
        @nloops $N x i->((1-S)/2:(S-1)/2)/S begin
            addindex!(bins, true, NearestInterpolation(), IndexAffineTransform(Dtrafo), @ntuple($N, i->x_i)...)
        end
        bins .*= inv(S^$N)
        ebins = MappedArray(bins, ConstantExterior())

        weights = Array{Array{$T, $M}, $M}(@ntuple $M i->D)
        @nloops $M d i->1:D begin
            iw = zeros($T, bins_num)
            @nloops $M b i->-bins_max[i]:bins_max[i] begin
                @nloops $M x i->1:D begin
                    @nref($M, iw, i->bins_max[i]-b_i+1) += @nref($M, ebins, i -> bins_offs[i] + (d_i-1) + (b_i)*D + (x_i-div(D,2)-1))
                end
            end
            @nref($M, weights, i->d_i) = iw
        end

        submap_type = SArray{Tuple{bins_num...}, $T, $M, prod(bins_num)}
        SArray{Tuple{@ntuple($M,i->D)...}, submap_type}(weights), @ntuple $M i -> bins_max[i]+1
    end
end

@generated function getindex{N,T}(A::MappedArray{<:Any, N, <:AbstractArray, <:MappedInterpolation{N,T}}, idx::Vararg{<:Number, N})
    quote
        $(Expr(:meta, :inline))

        @nextract $N idx idx

        @nexprs $N i -> sz_i = size(A.m.maps, i)
        @nexprs $N i -> @inbounds offs_i = A.m.offsets[i]

        @nexprs $N i -> sidx_i = unsafe_trunc(Int, round(sz_i*idx_i))
        @nexprs $N i -> iidx_i = fld(sidx_i, sz_i) - offs_i
        @nexprs $N i -> midx_i = 1 + mod(sidx_i, sz_i)

        @inbounds submap = @nref $N A.m.maps i->midx_i

        c = zero(T)
        @nloops $N x i->indices(submap, i) begin
            c += @nref($N, submap, i->x_i)*@nref($N, A.a, i->iidx_i+x_i)
        end
        c
    end
end

function setindex!(::MappedArray_byMap{<:MappedInterpolation}, _, ::Vararg{<:Number})
    throw(ArgumentError("setindex! is ill defined for mapped interpolation"))
    nothing
end

@generated function addindex!{N,T}(A::MappedArray{<:Any, N, <:AbstractArray, <:MappedInterpolation{N,T}}, val, idx::Vararg{<:Number, N})
    quote
        $(Expr(:meta, :inline))

        @nextract $N idx idx

        @nexprs $N i -> sz_i = size(A.m.maps, i)
        @nexprs $N i -> @inbounds offs_i = A.m.offsets[i]

        @nexprs $N i -> sidx_i = unsafe_trunc(Int, round(sz_i*idx_i))
        @nexprs $N i -> iidx_i = fld(sidx_i, sz_i) - offs_i
        @nexprs $N i -> midx_i = 1 + mod(sidx_i, sz_i)

        @inbounds submap = @nref $N A.m.maps i->midx_i

        c = zero(T)
        @nloops $N x i->indices(submap, i) begin
            @ncall $N addindex! A.a @nref($N, submap, i->x_i)*val i->iidx_i+x_i
        end
        c
    end
end
