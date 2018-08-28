using StaticArrays
using Base.Cartesian
using LinearAlgebra

export AffineTransform,
    LinearAffineTransform,
    StaticZeroVector,
    StaticUnitMatrix,
    axisrotate,
    rotate,
    translate,
    scale,
    unscale

import Base: size, eltype, show, getindex
import LinearAlgebra: det

import Base: (==), inv, (*), (+), (-)
import LinearAlgebra.A_mul_B!

(+)(a::SVector, b::Tuple) = a.data + b
(+)(a::Tuple, b::SVector) = a + b.data

"""
struct StaticZeroVector{N} <: StaticArray{Tuple{N}, Base.Bottom, 1} end
"""
struct StaticZeroVector{N} <: StaticArray{Tuple{N}, Base.Bottom, 1} end

"""
struct StaticUnitMatrix{N} <: StaticArray{Tuple{N,N}, Base.Bottom, 2} end
"""
struct StaticUnitMatrix{N} <: StaticArray{Tuple{N,N}, Base.Bottom, 2} end

getindex(::StaticZeroVector, ::Int) = false
getindex(::StaticUnitMatrix{N}, i::Int) where N = i%(N+1)==1
getindex(::StaticUnitMatrix{N}, i::Vararg{Union{Colon, Int64}}) where N = SMatrix{N, N, Bool}(I)[i...]

(-)(::StaticZeroVector{N}) where N = StaticZeroVector{N}()

(+)(::StaticZeroVector{N}, s::StaticVector{N}) where N = s
(+)(s::StaticVector{N}, ::StaticZeroVector{N}) where N = s
(+)(::StaticZeroVector{N}, ::StaticZeroVector{N}) where N= StaticZeroVector{N}()

(+)(::StaticZeroVector{N}, s::NTuple{N}) where N = s
(+)(s::NTuple{N}, ::StaticZeroVector{N}) where N = s

(*)(::StaticMatrix{M,N}, ::StaticZeroVector{N}) where {M,N} = StaticZeroVector{M}()
(*)(::SDiagonal{N}, ::StaticZeroVector{N}) where N = StaticZeroVector{N}()

(*)(::StaticUnitMatrix{N}, s::StaticVector{N}) where N = s
(*)(::StaticUnitMatrix{N}, s::NTuple{N}) where N = s
(*)(::StaticUnitMatrix{N}, ::StaticZeroVector{N}) where N = StaticZeroVector{N}()

(*)(::StaticUnitMatrix{N}, m::StaticMatrix{N,N}) where N = m
(*)(m::StaticMatrix{N,N}, ::StaticUnitMatrix{N}) where N = m
(*)(::StaticUnitMatrix{N}, m::SDiagonal{N}) where N = m
(*)(m::SDiagonal{N}, ::StaticUnitMatrix{N}) where N = m
(*)(::StaticUnitMatrix{N}, ::StaticUnitMatrix{N}) where N = StaticUnitMatrix{N}()

det(::StaticUnitMatrix) = true
inv(::StaticUnitMatrix{N}) where N = StaticUnitMatrix{N}()

"""
struct AffineTransform{N, MT<:StaticMatrix{N,N}, ST<:StaticVector{N}}
"""
struct AffineTransform{N, MT<:StaticMatrix{N,N}, ST<:StaticVector{N}}
    matrix::MT
    shift::ST
    AffineTransform(matrix::MT, shift::ST) where {N, MT<:StaticMatrix{N,N}, ST<:StaticVector{N}} = new{N,MT,ST}(matrix, shift)
end

LinearAffineTransform{N,MT<:StaticMatrix{N,N}} = AffineTransform{N, MT, StaticZeroVector{N}}

AffineTransform(shift::ST) where {N, ST<:SVector{N}} = AffineTransform(StaticUnitMatrix{N}(), shift)
AffineTransform(matrix::MT) where {N, MT<:StaticMatrix{N,N}} = AffineTransform(matrix, StaticZeroVector{N}())
AffineTransform{N}() where N = AffineTransform(StaticUnitMatrix{N}(), StaticZeroVector{N}())

function AffineTransform{N}(matrix::MT, shift::ST) where {N, MT<:AbstractMatrix, ST<:AbstractVector}
    @assert N == size(matrix,1) == size(shift,1) == size(matrix, 2)
    AffineTransform(SMatrix{N,N}(matrix), SVector{N}(shift))
end

AffineTransform(::Val{N}, args...) where N = AffineTransform{N}(args...)

@inline size(::AffineTransform{N}) where N = (N,N)
@inline size(::Type{A}) where {N, A<:AffineTransform{N}}= (N,N)

@inline eltype(::AffineTransform{N,MT,ST}) where {N,MT,ST} = Base.promote_eltype(MT, ST)

@inline inv(at::AffineTransform{N}) where N= let matrix = inv(at.matrix); AffineTransform(matrix, -(matrix*at.shift)); end

### Combination of AffineTransforms

@inline (*)(A::AffineTransform{N}, B::AffineTransform{N}) where N = AffineTransform(A.matrix*B.matrix, (A.matrix*B.shift)+A.shift)

### Application of AffineTransforms

@inline (*)(A::AffineTransform, v::SVector{N}) where N = SVector(A*ntuple(i->v[i], Val(N)))

@generated function (*)(A::AffineTransform{N, <:SMatrix}, v::Tuple{Vararg{T, N} where T}) where N
    quote
        $(Expr(:meta, :inline))
        $(Expr(:meta, :inbounds))
        i_0 = @ntuple $N i -> i<=$N ? A.shift[i] : false
        #$(Expr(:block, (:($(Symbol("i_", j)) = @ntuple $N k -> fma(A.matrix[k,$j], v[$j], $(Symbol("i_",j-1))[k])) for j in 1:N)...))
        $(Expr(:block, (:($(Symbol("i_", j)) = @ntuple $N k -> A.matrix[k,$j]*v[$j]+$(Symbol("i_",j-1))[k]) for j in 1:N)...))
    end
end

@generated function (*)(A::AffineTransform{N, <:SDiagonal}, v::Tuple{Vararg{T, N} where T}) where N
    quote
        $(Expr(:meta, :inline))
        $(Expr(:meta, :inbounds))
        @ntuple $N j -> fma(diag(A.matrix)[j], v[j], A.shift[j])
    end
end

@inline (*)(A::AffineTransform{N, StaticUnitMatrix{N}, StaticZeroVector{N}}, v::Tuple{Vararg{T, N} where T}) where N = v
@inline (*)(A::AffineTransform{N, StaticUnitMatrix{N}}, v::Tuple{Vararg{T, N} where T}) where N = tuple(A.shift...).+v

### Convenient Constructors

@inline scale(a::AffineTransform) = AffineTransform(a.matrix)

@inline function scale(s::Vararg{AbstractRange, N}) where N
    AffineTransform(SDiagonal(map(step, s)), SVector{N}([first(i)-step(i) for i in s]))
end

@inline function scale(s::Vararg{Number, N}) where N
    AffineTransform(SDiagonal(s), StaticZeroVector{N}())
end

@inline scale(s::Vararg{Union{AbstractRange, Number}, N}) where N = scale(s)

@inline @generated function scale(s::T) where {N, T<:Tuple{Vararg{Union{AbstractRange, Number}, N}}}
    quote
        AffineTransform(SDiagonal($(Expr(:tuple, ntuple(i->T.parameters[i]<:AbstractRange ? :(step(s[$i])) : :(s[$i]), Val(N))...))), SVector($(Expr(:tuple, ntuple(i->T.parameters[i]<:AbstractRange ? :(first(s[$i])-step(s[$i])) : :(zero($(T.parameters[i]))), Val(N))...))))
    end
end

@inline function unscale(s::Vararg{AbstractRange, N}) where N
    AffineTransform(SDiagonal(map(inv ∘ step, s)), SVector{N}(map(i -> -first(i)/step(i)+1, [s...])))
end

function rotate(a)
    ca = cos(a)
    sa = sin(a)
    AffineTransform(SMatrix{2,2}([ca -sa; sa ca]))
end

function axisrotate(x::NTuple{3, T}, a::AT) where {T,AT}
    nx = x./norm(x)
    PT = promote_type(T, AT, Float64)
    c = cos(a)
    s = sin(a)

    matrix = @SMatrix [ i==j ?
                        c + (1-c)*nx[i]*nx[j] :
                        s * (iseven(mod1(i-j, 3)) ? -nx[6-i-j] : nx[6-i-j]) + (1-c)*nx[i]*nx[j]
                        for i in 1:3, j in 1:3 ]
    
    AffineTransform(matrix)
end

@inline translate(s::S where S<:SVector{N, T}) where {N, T<:Real} = AffineTransform(SMatrix{N,N, T}(I), SVector{N}(s))
@inline translate(s::Tuple{Vararg{<:Real, N}}) where {N} = AffineTransform(SMatrix{N,N}(I), SVector{N}(s))
@inline translate(s::Vararg{Real}) = translate(promote(s...))
