using StaticArrays
using Base.Cartesian

export AffineTransform, axisrotate, rotate, translate, scale, unscale

import Base: size, eltype, show

import Base: (==), inv, (*), A_mul_B!, (+)

"type for affine transformation based a NxN SMatrix and a N SVector representing linear and absolute components of the transform"
struct AffineTransform{N, MT<:SMatrix{N,N}, ST<:SVector{N}}
    matrix::MT
    shift::ST
    AffineTransform(matrix::MT, shift::ST) where {N, MT<:SMatrix{N,N}, ST<:SVector{N}} = new{N,MT,ST}(matrix,shift)
end

AffineTransform{N}(matrix::MT=eye(SMatrix{N,N}), shift::ST=zeros(SVector{N})) where {N, MT<:SMatrix{N,N}, ST<:SVector{N}} = AffineTransform(matrix, shift)

AffineTransform(matrix::MT) where {N, MT<:SMatrix{N,N}} = AffineTransform(matrix, zeros(SVector{N, eltype(MT)}))

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

function (*){N}(A::AffineTransform{N}, B::AffineTransform{N})
    AffineTransform{N}(A.matrix*B.matrix, A.shift+A.matrix*B.shift)
end

function (*)(A::AffineTransform, v::AbstractVector)
    A.matrix*v.+A.shift
end

function A_mul_B!(u::AbstractVector, A::AffineTransform, v::AbstractVector)
    u .= A*v
end

#TODO deprecate if StaticArrays defines corresponding method
@generated function (*){N, SM<:SMatrix{N,N}, VT<:NTuple{N, Any}}(sm::SM, vt::VT)
    :(@ntuple $N i -> $(Expr(:call, :+, (:(sm[i,$j] * vt[$j]) for j in 1:N)...)))
end

@generated function (+){N, SV<:SVector{N}, VT<:NTuple{N, Any}}(vt::VT, sv::SV)
    :(@ntuple $N i->sv[i]+vt[i])
end
(+){N}(sv::SV where SV<:SVector{N}, vt::VT where VT<:NTuple{N, Any}) = vt+sv


function (*){N, V<:NTuple{N, Any}}(A::AffineTransform{N}, v::V)
    A.matrix*v+A.shift
end

# Convenient Constructors

function rotate(a)
    ca = cos(a)
    sa = sin(a)
    AffineTransform(SMatrix{2,2}([ca -sa; sa ca]))
end

function axisrotate{T, AT}(x::NTuple{3, T}, a::AT)
    PT = promote_type(T, AT, Float64)
    ca = 1-cos(a)
    sa = sin(a)

    matrix  = SMatrix{3,3}(PT[(i==j ? 1+ca*(-x[i%3+1]^2-x[(i+1)%3+1]^2) : x[i]*x[j])+sa*(i!=j ? -1^((i>j)+i-j)*x[(5-i-j)%3+1] : 0) for i in 1:3, j in 1:3])

    AffineTransform(matrix)
end

@inline translate{N, T<:Real}(s::S where S<:SVector{N, T}) = AffineTransform{N}(eye(SMatrix{N,N, T}), SVector{N}(s))
@inline translate{N, T<:Real}(s::NTuple{N, T}) = AffineTransform{N}(eye(SMatrix{N,N, T}), SVector{N}(s))
@inline translate{N, T<:NTuple{N, Real}}(s::T) = translate(promote(s...))

function scale{N}(s::Vararg{Range, N})
    AffineTransform(SMatrix{N,N}(diagm(map(step, [s...]))), SVector{N}(map(is -> first(is)-step(is), [s...])))
end

function unscale{N}(s::Vararg{Range, N})
    AffineTransform(SMatrix{N,N}(diagm(map(inv ∘ step, [s...]))), SVector{N}(map(is -> -first(is)/step(is)+1, [s...])))
end
