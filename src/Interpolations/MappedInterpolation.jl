import Base: getindex, setindex!
import ATINEH:addindex!

using Base.Cartesian
using OffsetArrays

export MappedInterpolation, VolumetricInterpolation

struct MappedInterpolation{N, T, AT<:AbstractArray{<:AbstractArray{T,N},N}} <: AbstractIndexingModifier
    maps::AT
    MappedInterpolation(maps::AT) where {N, T, AT<:AbstractArray{<:AbstractArray{T,N},N}} = new{N, T, AT}(maps)
end

struct VolumetricInterpolation <: AbstractIndexingModifier
    S::Int
    D::Int
    VolumetricInterpolation(S::Int=32, D::Int=8) = new(S,D)
end

VolumetricInterpolation(trafo::AffineTransform, S::Int=32, D::Int=8) = MappedInterpolation(flatcube(trafo, S, D))

@inline subindex{I<:Integer}(a::I, s::Int) = one(I)

@inline function subindex{T<:Base.Math.IEEEFloat}(a::T, s::Int)
    us = reinterpret(Unsigned, a)
    e = ((us & Base.exponent_mask(T)) >>> Base.Math.significand_bits(T)) - (Base.Math.exponent_bias(T) - 32)
    b = (Base.significand_mask(T) & us)
    c = (b >>> (Base.Math.significand_bits(T)-e)) | (one(UInt) << e)
    d = copysign(c, a) & (zero(UInt32)-one(UInt32))
    reinterpret(Int, 1+((d*s) >>> 32))
end

@generated function flatcube{M,N}(trafo::AffineTransform{M,N}, S, D)
    T = Float64
    quote
        bins_max = @ntuple $M i -> ceil(Int, sum(abs, trafo.matrix[:,i]))
        bins_nums = @ntuple $M i -> 1+2*bins_max[i]
        bins_idims = @ntuple $M i -> -bins_max[i]:bins_max[i]
        bins_dims = @ntuple $M i -> (-bins_max[i]-(1-1/D)/2):1/D:(bins_max[i]+(1-1/D)/2)
        Dtrafo = unscale(bins_dims...)*AffineTransform(trafo.matrix)
        bins = zeros(map(length, bins_dims))
        @nloops $N x i->((1-S)/2:(S-1)/2)/S begin
            addindex!(bins, (1/S)^$M, LinearInterpolation(), IndexAffineTransform(Dtrafo), @ntuple($N, i->x_i)...)
        end
        weights = Array{OffsetArray{eltype(bins), $M, Array{eltype(bins), $M}}, $M}(@ntuple $M i->D)
        @nloops $M d i->1:D begin
            @nref($M, weights, i->d_i) = OffsetArray(zeros(eltype(bins), @ntuple $M i->bins_nums[i]), bins_idims)
            iw = @nref($M, weights, i->d_i).parent
            @nloops $M b i->1:bins_nums[i] begin
                @nloops $M x i->1:D begin
                    @nref($M, iw, i->bins_nums[i]-b_i+1) += @nref($M, bins, i->((d_i-1)+(b_i-1)*D+(x_i-1))%(D*bins_nums[i])+1)
                end
            end
        end
        weights
    end
end

@generated function getindex{N,T}(A::MappedArray{<:Any, N, <:AbstractArray, <:MappedInterpolation{N,T}}, idx::Vararg{<:Number, N})
    quote
        $(Expr(:meta, :inline))

        @nexprs $N i -> iidx_i = floor(idx[i])
        @nexprs $N i -> iiidx_i = unsafe_trunc(Int, iidx_i)

        maps = A.m.maps
        submap = @nref $N maps i->subindex(idx[i], size(maps, i))

        a = A.a
        c = zero(T)
        @nloops $N x i->indices(submap, i) begin
            c += @nref($N, a, i->iiidx_i+x_i)*@nref($N, submap, i->x_i)
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

        @nexprs $N i -> iidx_i = floor(idx[i])
        @nexprs $N i -> iiidx_i = unsafe_trunc(Int, iidx_i)

        maps = A.m.maps
        submap = @nref $N maps i-> 1+unsafe_trunc(Int, floor(size(maps, i)*(idx[i]-iidx_i)))

        c = zero(T)
        @nloops $N x i->indices(submap, i) begin
            @ncall $N addindex! A.a @nref($N, submap, i->x_i)*val i->iiidx_i+x_i
        end
        c
    end
end
