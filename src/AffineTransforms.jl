using StaticArrays
using Base.Cartesian

export AffineTransform, axisrotate, rotate, translate, scale, unscale, StaticZeroVector, StaticUnitMatrix

import Base: size, eltype, show, getindex, permutedims, det

import Base: (==), inv, (*), A_mul_B!, (+), (-)

"""
struct StaticZeroVector{N} <: StaticArray{Tuple{N}, Base.Bottom, 1} end
"""
struct StaticZeroVector{N} <: StaticArray{Tuple{N}, Base.Bottom, 1} end

"""
struct StaticUnitMatrix{N} <: StaticArray{Tuple{N,N}, Base.Bottom, 2} end
"""
struct StaticUnitMatrix{N} <: StaticArray{Tuple{N,N}, Base.Bottom, 2} end

getindex(::StaticZeroVector, ::Int) = false
getindex{N}(::StaticUnitMatrix{N}, i::Int) = i%(N+1)==1
getindex{N}(::StaticUnitMatrix{N}, I::Vararg{Union{Colon, Int64}}) = @SMatrix(eye(Bool, N))[I...]

(-){N}(::StaticZeroVector{N}) = StaticZeroVector{N}()

(+){N}(::StaticZeroVector{N}, s::StaticVector{N}) = s
(+){N}(s::StaticVector{N}, ::StaticZeroVector{N}) = s
(+){N}(::StaticZeroVector{N}, ::StaticZeroVector{N}) = StaticZeroVector{N}()

(+){N}(::StaticZeroVector{N}, s::NTuple{N}) = s
(+){N}(s::NTuple{N}, ::StaticZeroVector{N}) = s

(*){M,N}(::StaticMatrix{M,N}, ::StaticZeroVector{N}) = StaticZeroVector{M}()
(*){N}(::SDiagonal{N}, ::StaticZeroVector{N}) = StaticZeroVector{N}()

(*){N}(::StaticUnitMatrix{N}, s::StaticVector{N}) = s
(*){N}(::StaticUnitMatrix{N}, s::NTuple{N}) = s
(*){N}(::StaticUnitMatrix{N}, ::StaticZeroVector{N}) = StaticZeroVector{N}()

(*){N}(::StaticUnitMatrix{N}, m::StaticMatrix{N,N}) = m
(*){N}(m::StaticMatrix{N,N}, ::StaticUnitMatrix{N}) = m
(*){N}(::StaticUnitMatrix{N}, m::SDiagonal{N}) = m
(*){N}(m::SDiagonal{N}, ::StaticUnitMatrix{N}) = m
(*){N}(::StaticUnitMatrix{N}, ::StaticUnitMatrix{N}) = StaticUnitMatrix{N}()

det(::StaticUnitMatrix) = true
inv{N}(::StaticUnitMatrix{N}) = StaticUnitMatrix{N}()

"""
struct AffineTransform{M, N, MT<:StaticMatrix{M,N}, ST<:StaticVector{M}}
"""
struct AffineTransform{M, N, MT<:StaticMatrix{M,N}, ST<:StaticVector{M}}
    matrix::MT
    shift::ST
    AffineTransform(matrix::MT, shift::ST) where {M,N, MT<:StaticMatrix{M,N}, ST<:StaticVector{M}} = new{M,N,MT,ST}(matrix, shift)
end

AffineTransform(shift::ST) where {N, ST<:SVector{N}} = AffineTransform(StaticUnitMatrix{N}(), shift)
AffineTransform(matrix::MT) where {M, N, MT<:StaticMatrix{M,N}} = AffineTransform(matrix, StaticZeroVector{M}())
AffineTransform{N}() where N = AffineTransform(StaticUnitMatrix{N}(), StaticZeroVector{N}())

function AffineTransform{M,N}(matrix::MT, shift::ST) where {M, N, MT<:AbstractMatrix, ST<:AbstractVector}
    @assert M == size(matrix,1) == size(shift,1)
    @assert N == size(matrix, 2)
    AffineTransform{N}(SMatrix{N,N}(matrix), SVector{N}(shift))
end

AffineTransform{N}(::Type{Val{N}}, args...) = AffineTransform{N}(args...)

@inline size{M,N}(::AffineTransform{M,N}) = (M,N)
@inline size{M,N, A<:AffineTransform{M,N}}(::Type{A}) = (M,N)

@inline eltype{M,N,MT,ST}(::AffineTransform{M,N,MT,ST}) = Base.promote_eltype(MT, ST)

@inline inv{N}(at::AffineTransform{N,N}) = let matrix = inv(at.matrix); AffineTransform(matrix, -(matrix*at.shift)); end

### Combination of AffineTransforms

@inline (*){M,N,O}(A::AffineTransform{M,N}, B::AffineTransform{N,O}) = AffineTransform(A.matrix*B.matrix, (A.matrix*B.shift)+A.shift)

### Application of AffineTransforms

@inline (*){N}(A::AffineTransform, v::SVector{N}) = SVector(A*ntuple(i->v[i], Val{N}))

@generated function (*){M,N}(A::AffineTransform{M,N, <:SMatrix}, v::Tuple{Vararg{T, N} where T})
    quote
        $(Expr(:meta, :inline))
        i_0 = @ntuple $M i -> i<=$N ? A.shift[i] : false
        $(Expr(:block, (:($(Symbol("i_", j)) = @ntuple $M k -> fma(A.matrix[k,$j], v[$j], $(Symbol("i_",j-1))[k])) for j in 1:N)...))
    end
end

@generated function (*){N}(A::AffineTransform{N,N, <:SDiagonal}, v::Tuple{Vararg{T, N} where T})
    quote
        $(Expr(:meta, :inline))
        @ntuple $N j -> fma(diag(A.matrix)[j], v[j], A.shift[j])
    end
end

@inline (*){N}(A::AffineTransform{N,N, StaticUnitMatrix{N}, StaticZeroVector{N}}, v::Tuple{Vararg{T, N} where T}) = v
@inline (*){N}(A::AffineTransform{N,N, StaticUnitMatrix{N}}, v::Tuple{Vararg{T, N} where T}) = A.shift*v

### Convenient Constructors

@generated function permutedims{N,M}(::Type{Val{N}}, d::Vararg{Int,M})
    quote
        Expr(:meta, :inline)
        AffineTransform(SMatrix{M, N}(tuple($([:($i==d[$j]) for i in 1:N for j in 1:M]...))))
    end
end

@inline scale(a::AffineTransform) = AffineTransform(a.matrix)

@inline function scale{N}(s::Vararg{Range, N})
    AffineTransform(SDiagonal(map(step, s)), SVector{N}([first(i)-step(i) for i in s]))
end

@inline function scale{N}(s::Vararg{Number, N})
    AffineTransform(SDiagonal(s), StaticZeroVector{N}())
end

@inline scale{N}(s::Vararg{Union{Range, Number}, N}) = scale(s)

@inline @generated function scale{N, T<:Tuple{Vararg{Union{Range, Number}, N}}}(s::T)
    quote
        AffineTransform(SDiagonal($(Expr(:tuple, ntuple(i->T.parameters[i]<:Range ? :(step(s[$i])) : :(s[$i]), Val{N})...))), SVector($(Expr(:tuple, ntuple(i->T.parameters[i]<:Range ? :(first(s[$i])-step(s[$i])) : :(zero($(T.parameters[i]))), Val{N})...))))
    end
end

@inline function unscale{N}(s::Vararg{Range, N})
    AffineTransform(SDiagonal(map(inv ∘ step, s)), SVector{N}(map(i -> -first(i)/step(i)+1, [s...])))
end

function rotate(a)
    ca = cos(a)
    sa = sin(a)
    AffineTransform(SMatrix{2,2}([ca -sa; sa ca]))
end

function axisrotate{T, AT}(x::NTuple{3, T}, a::AT)
    nx = x./vecnorm(x)
    PT = promote_type(T, AT, Float64)
    c = cos(a)
    s = sin(a)

    matrix = @SMatrix [ i==j ?
                        c + (1-c)*nx[i]*nx[j] :
                        s * (iseven(mod1(i-j, 3)) ? -nx[6-i-j] : nx[6-i-j]) + (1-c)*nx[i]*nx[j]
                        for i in 1:3, j in 1:3 ]
    
    AffineTransform(matrix)
end

@inline translate{N, T<:Real}(s::S where S<:SVector{N, T}) = AffineTransform(eye(SMatrix{N,N, T}), SVector{N}(s))
@inline translate{N, T<:Real}(s::NTuple{N, T}) = AffineTransform(eye(SMatrix{N,N, T}), SVector{N}(s))
@inline translate(s::Vararg{Real}) = translate(promote(s...))
