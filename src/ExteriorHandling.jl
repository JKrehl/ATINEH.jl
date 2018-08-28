import Base: getindex, setindex!

export ConstantExterior, InBounds


"conversion for numerical element types with special rule for Tuple{...} types"
@inline elconvert(::Type{T}, x) where T = T(x)

@generated function elconvert(::Type{T}, x) where {T<:Tuple}
    Expr(:block, Expr(:meta, :inline), Expr(:tuple, (:($t(x)) for t in T.types)...))
end

struct ConstantExterior{T} <: AbstractIndexingModifier
    value::T
    ConstantExterior(value::T=0) where {T} = new{T}(value)
    ConstantExterior{T}() where {T} = new{T}(zero(T))
end

@propagate_inbounds function getindex(A::MappedArray{T, <:Any, <:Any, <:ConstantExterior}, idx::Vararg{<:Number}) where T
    @boundscheck if !checkbounds(Bool, A.array, idx...); return T(A.map.value); end
    @inbounds re = getindex(A.array, idx...)
    re
end

@propagate_inbounds function setindex!(A::MappedArray_byMap{<:ConstantExterior}, val, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A.array, idx...); return A.array; end
    @inbounds re = setindex!(A.array, val, idx...)
    A.array
end

@propagate_inbounds function addindex!(A::MappedArray_byMap{<:ConstantExterior}, val, idx::Vararg{<:Number})
    @boundscheck if !checkbounds(Bool, A.array, idx...); return A.array; end
    @inbounds re = addindex!(A.array, val, idx...)
    A.array
end

struct InBounds <: AbstractIndexingModifier end

@propagate_inbounds function getindex(A::MappedArray_byMap{<:InBounds}, idx::Vararg{<:Number})
    @inbounds re = getindex(A.array, idx...)
    re
end

@propagate_inbounds function setindex!(A::MappedArray_byMap{<:InBounds}, val, idx::Vararg{<:Number})
    @inbounds re = setindex!(A.array, val, idx...)
    re
end

@propagate_inbounds function addindex!(A::MappedArray_byMap{<:InBounds}, val, idx::Vararg{<:Number})
    @inbounds re = addindex!(A.array, val, idx...)
    re
end
