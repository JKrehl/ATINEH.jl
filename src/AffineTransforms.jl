using StaticArrays
using Base.Cartesian

export AffineTransform, axisrotate, rotate, translate, scale, unscale, SMatrix, SVector

import Base: size, eltype, show

import Base: (==), inv, (*), A_mul_B!, (+)

"type for affine transformation based a NxN SMatrix and a N SVector representing linear and absolute components of the transform"
struct AffineTransform{N, MT<:StaticArray{Tuple{N,N}}, ST<:StaticArray{Tuple{N}}}
    matrix::MT
    shift::ST
    AffineTransform(matrix::MT, shift::ST) where {N, MT<:StaticArray{Tuple{N,N}}, ST<:StaticArray{Tuple{N}}} = new{N,MT,ST}(matrix,shift)
end

AffineTransform(shift::ST) where {N, ST<:SVector{N}} = AffineTransform(eye(SDiagonal{N, eltype(ST)}))
AffineTransform(matrix::MT) where {N, MT<:StaticArray{Tuple{N,N}}} = AffineTransform(matrix, zeros(SVector{N, eltype(MT)}))

function AffineTransform{N}(matrix::MT, shift::ST) where {N, MT<:AbstractMatrix, ST<:AbstractVector}
    @assert N == size(matrix,1) == size(matrix, 2) == size(shift,1)
    AffineTransform{N}(SMatrix{N,N}(matrix), SVector{N}(shift))
end

AffineTransform{N}(::Type{Val{N}}, args...) = AffineTransform{N}(args...)

# Essential Functions

@inline size{N}(::AffineTransform{N}) = N
@inline size{N, A<:AffineTransform{N}}(::Type{A}) = N

@inline eltype{N,MT,ST}(::AffineTransform{N,MT,ST}) = Base.promote_eltype(MT, ST)

function show(io::IO, tf::AffineTransform)
    println(io, typeof(tf), ":")
    println(io, "matrix: ", tf.matrix)
    println(io, "shift: ", tf.shift)
end

# Mathematical Functions

(==)(A::AffineTransform, B::AffineTransform) = A.matrix == B.matrix && A.shift == B.shift

function inv(A::AffineTransform)
    matrix = inv(A.matrix)
    AffineTransform(matrix, -matrix*A.shift)
end

@inline function (*){N}(A::AffineTransform{N}, B::AffineTransform{N})
    AffineTransform(A.matrix*B.matrix, A.shift+A.matrix*B.shift)
end

@inline function (*)(A::AffineTransform, v::AbstractVector)
    A.matrix*v.+A.shift
end

@inline function A_mul_B!(u::AbstractVector, A::AffineTransform, v::AbstractVector)
    u .= A*v
end

@generated function (*){N}(A::AffineTransform{N, <:SMatrix}, v::Tuple{Vararg{Real,N}})
    exs = [:($(Symbol("re_",i)) = @ntuple $N j -> muladd(A.matrix[j, $i], v[$i], $(Symbol("re_",i-1))[j])) for i in 2:N]
    quote
        $(Expr(:meta, :inline))
        re_1 = @ntuple $N j -> muladd(A.matrix[j, 1], v[1], A.shift[j])
        $(exs...)
    end
end

@generated function (*){N}(A::AffineTransform{N, <:SDiagonal}, v::Tuple{Vararg{Real,N}})
    quote
        $(Expr(:meta, :inline))
        re = @ntuple $N j -> muladd(diag(A.matrix)[j], v[j], A.shift[j])
    end
end

# Convenient Constructors

function rotate(a)
    ca = cos(a)
    sa = sin(a)
    AffineTransform(SMatrix{2,2}([ca -sa; sa ca]))
end

function axisrotate{T, AT}(x::NTuple{3, T}, a::AT)
    nx = x./vecnorm(x)
    PT = promote_type(T, AT, Float64)
    c = cos(a/2)
    s = sin(a/2)

    matrix  = @SMatrix [i==j ? (2*(nx[i]^2-1)*s^2 + 1) : (2*nx[i]*nx[j] - (-1)^(i>j ? i+j : i+j+1)*2*nx[6-i-j]*c*s) for i in 1:3, j in 1:3]

    AffineTransform(matrix)
end

@inline translate{N, T<:Real}(s::S where S<:SVector{N, T}) = AffineTransform{N}(eye(SMatrix{N,N, T}), SVector{N}(s))
@inline translate{N, T<:Real}(s::NTuple{N, T}) = AffineTransform{N}(eye(SMatrix{N,N, T}), SVector{N}(s))
@inline translate{N, T<:NTuple{N, Real}}(s::T) = translate(promote(s...))

@inline function scale{N}(s::Vararg{Range, N})
    AffineTransform(SDiagonal(map(step, s)), SVector{3}([first(i)-step(i) for i in s]))
end

@inline function unscale{N}(s::Vararg{Range, N})
    AffineTransform(SDiagonal(map(inv ∘ step, [s...])), SVector{N}(map(i -> -first(i)/step(i)+1, [s...])))
end
