import Base: convert, (∘), getindex, setindex!, first, tail, @propagate_inbounds

export addindex!
export AbstractIndexingModifier, MappedArray, MappedArray_byMap, IndexIdentity, AsType, PermuteIndices, ConstantInterior

IndexTypes = Union{Number, Tuple, AffineTransform}

@propagate_inbounds addindex!(A::AbstractArray, value, i...) = begin @boundscheck checkbounds(A, i...); @inbounds A[i...] += value; A end
@propagate_inbounds addindex!(A::AbstractArray, value, i::CartesianIndex) = addindex!(A, value, Tuple(i)...)

"abstract index map"
abstract type AbstractIndexingModifier end

"an array annotated with an index map"
struct MappedArray{T, N, A<:AbstractArray, M<:AbstractIndexingModifier} <: AbstractArray{T,N}
    array::A
    map::M
    MappedArray(array::A, map::M) where {T, N, A<:AbstractArray{T,N}, M<:AbstractIndexingModifier} = new{T,N,A,M}(array, map)
    MappedArray{T}(array::A, map::M) where {T, N, S, A<:AbstractArray{S,N}, M<:AbstractIndexingModifier} = new{T,N,A,M}(array, map)
    MappedArray{T, N}(array::A, map::M) where {T, N, A<:AbstractArray, M<:AbstractIndexingModifier} = new{T,N,A,M}(array, map)
end
MappedArray_byMap{I} = MappedArray{<:Any,<:Any,<:Any,I}

@inline size(ma::MappedArray) = size(ma.array)

@propagate_inbounds getindex(A::AbstractArray, m::AbstractIndexingModifier, x...) = getindex(MappedArray(A, m), x...)
@propagate_inbounds setindex!(A::AbstractArray, val,  m::AbstractIndexingModifier, x...) = setindex!(MappedArray(A, m), val, x...)
@propagate_inbounds addindex!(A::AbstractArray, val,  m::AbstractIndexingModifier, x...) = addindex!(MappedArray(A, m), val, x...)

@propagate_inbounds getindex(A::MappedArray, x::CartesianIndex) = getindex(A, Tuple(x)...)
@propagate_inbounds setindex!(A::MappedArray, v, x::CartesianIndex) = setindex!(A, v, Tuple(x)...)
@propagate_inbounds addindex!(A::MappedArray, v, x::CartesianIndex) = addindex!(A, v, Tuple(x)...)

"convert elements to new type"
struct AsType{T} <: AbstractIndexingModifier
    AsType(::Type{T}) where T = new{T}()
end

@propagate_inbounds getindex(A::AbstractArray , m::AsType{T}, x::Vararg) where T = getindex(MappedArray{T}(A, m), x...)
@propagate_inbounds setindex!(A::AbstractArray, val,  m::AsType{T}, x::Vararg) where T = setindex!(MappedArray{T}(A, m), val, x...)
@propagate_inbounds addindex!(A::AbstractArray, val,  m::AsType{T}, x::Vararg) where T = addindex!(MappedArray{T}(A, m), val, x...)

@propagate_inbounds function getindex(A::MappedArray_byMap{AsType{T}}, x::Vararg{<:IndexTypes}) where T
    T(getindex(A.array, x...))
end

@propagate_inbounds setindex!(A::MappedArray_byMap{<:AsType}, val, x::Vararg{<:IndexTypes}) = setindex!(A.array, val, x...)
@propagate_inbounds addindex!(A::MappedArray_byMap{<:AsType}, val, x::Vararg{<:IndexTypes}) = addindex!(A.array, val, x...)

"index map without effect"
struct IndexIdentity<: AbstractIndexingModifier end

@propagate_inbounds getindex(A::MappedArray_byMap{IndexIdentity}, x::Vararg{<:IndexTypes}) = getindex(A.array, x...)
@propagate_inbounds setindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = setindex!(A.array, val, x...)
@propagate_inbounds addindex!(A::MappedArray_byMap{IndexIdentity}, val, x::Vararg{<:IndexTypes}) = addindex!(A.array, val, x...)

"return constant value instead of value in array"
struct ConstantInterior{T} <: AbstractIndexingModifier
    value::T
end
@propagate_inbounds getindex(A::AbstractArray , m::ConstantInterior{T}, x::Vararg) where T = getindex(MappedArray{T}(A, m), x...)
@propagate_inbounds setindex!(A::AbstractArray, val,  m::ConstantInterior{T}, x::Vararg) where T = nothing
@propagate_inbounds addindex!(A::AbstractArray, val,  m::ConstantInterior{T}, x::Vararg) where T = nothing


@propagate_inbounds getindex(A::MappedArray_byMap{<:ConstantInterior}, x::Vararg{<:IndexTypes}) = A.map.value
@propagate_inbounds setindex!(A::MappedArray_byMap{<:ConstantInterior}, val, x::Vararg{<:IndexTypes}) = nothing
@propagate_inbounds addindex!(A::MappedArray_byMap{<:ConstantInterior}, val, x::Vararg{<:IndexTypes}) = nothing


"""
    a fun helper function
"""
@generated function valrangetuple(::Type{Val{N}}) where N
    quote
        $(Expr(:meta, :inline))
        Val{$(Expr(:tuple, (1:N)...))}()
    end
end


"""
    struct PermuteIndices{P} <: AbstractIndexingModifier
    P is a tuple of ints permuting (or dropping or repeating) indices
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Val{P}) where P = new{P}()
"""
struct PermuteIndices{P} <: AbstractIndexingModifier
    PermuteIndices{P}() where P = new{P}()
    PermuteIndices(::Val{P}) where P = new{P}()
end

PermuteIndices(P::Vararg{Int}) = PermuteIndices{P}()

@generated function getindex(A::MappedArray_byMap{PermuteIndices{P}}, x::Vararg{<:IndexTypes,N}) where {P,N}
    @assert all(map(i->i<=N,P))
    quote
        $(Expr(:meta, :inline, :propagate_inbounds))
        @inbounds @ntuple($N, i->ix_i) = x
        getindex(A.array, $((Symbol(:ix_, i) for i in P)...))
    end
end

@generated function setindex!(A::MappedArray_byMap{PermuteIndices{P}}, val, x::Vararg{<:IndexTypes,N}) where {P,N}
    @assert all(map(i->i<=N,P))
    quote
        $(Expr(:meta, :inline, :propagate_inbounds))
        @inbounds @ntuple($N, i->ix_i) = x
        setindex!(A.array, val, $((Symbol(:ix_, i) for i in P)...))
    end
end

@generated function addindex!(A::MappedArray_byMap{PermuteIndices{P}}, val, x::Vararg{<:IndexTypes,N}) where {P,N}
    @assert all(map(i->i<=N,P))
    quote
        $(Expr(:meta, :inline, :propagate_inbounds))
        @inbounds @ntuple($N, i->ix_i) = x
        addindex!(A.array, val, $((Symbol(:ix_, i) for i in P)...))
    end
end
