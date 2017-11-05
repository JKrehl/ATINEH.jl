import Base: getindex, setindex!
import ATINEH:addindex!

using Base.Cartesian
using OffsetArrays

export MappedInterpolation

struct MappedInterpolation{N, T, AT<:AbstractArray{<:AbstractArray{T,N},N}} <: AbstractIndexingModifier
    maps::AT
    offsets::NTuple{N, Int}
    MappedInterpolation(maps::AT, offsets::NTuple{N,Int}=ntuple(i->0, Val{N})) where {N, T, AT<:AbstractArray{<:AbstractArray{T,N},N}} = new{N, T, AT}(maps, offsets)
end

@inline subindex{I<:Integer}(a::I, s::Int) = one(I)

@inline function subindex{T<:Base.Math.IEEEFloat}(a::T, s::Int)
    us = reinterpret(Unsigned, a)
    e = ((us & Base.exponent_mask(T)) >>> Base.Math.significand_bits(T)) - (Base.Math.exponent_bias(T) - 32)
    b = (Base.significand_mask(T) & us)
    c = (b >>> (Base.Math.significand_bits(T)-e)) | (one(UInt) << e)
    d = copysign(c, a) & (zero(UInt32)-one(UInt32))
    reinterpret(Int, 1+((d*s) >>> 32))
end

@generated function getindex{N,T}(A::MappedArray{<:Any, N, <:AbstractArray, <:MappedInterpolation{N,T}}, idx::Vararg{<:Number, N})
    quote
        $(Expr(:meta, :inline))
        $(Expr(:meta, :propagate_inbounds))

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
        $(Expr(:meta, :propagate_inbounds))

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
