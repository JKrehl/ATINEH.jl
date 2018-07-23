import Base: getindex, setindex!
import ATINEH:addindex!

export LinearInterpolation

struct LinearInterpolation <: AbstractInterpolation
end

@generated function getindex(A::MappedArray{T,<:Any,<:Any,<:LinearInterpolation}, I::Vararg{<:Number, N}) where {N,T}
    
    ex = :(@ncall $N getindex A.array i->x_i)
    for i in 1:N
        x_ = Symbol("x_", i)
        idx_ = Symbol("idx_", i)
        rdx_ = Symbol("rdx_", i)
        ex = quote
            local r1 = let $x_ = $idx_
               (one($rdx_)-$rdx_) * $ex
            end
            local r2 = let $x_ = $idx_+1
                $rdx_ * $ex
            end
            r1+r2
        end
    end
    
    quote
        $(Expr(:meta, :inline))
        $(Expr(:meta, :propagate_inbounds))
        
        @nexprs $N i -> begin
            fdx_i = floor(I[i])
            idx_i = unsafe_trunc(Int, fdx_i)
            rdx_i = I[i] - fdx_i
        end
        
        $ex
    end
end


function setindex!(::MappedArray_byMap{<:LinearInterpolation}, _, ::Vararg{<:Number})
    throw(ArgumentError("setindex! is ill defined for LinearInterpolation"))
    nothing
end

@generated function addindex!(A::MappedArray{T,<:Any,<:Any,<:LinearInterpolation}, val, I::Vararg{<:Number, N}) where {N,T}
    
    ex = :(@ncall $N addindex! A.array val i->x_i)

    for i in 1:N
        x_ = Symbol("x_", i)
        idx_ = Symbol("idx_", i)
        rdx_ = Symbol("rdx_", i)
        
        ex = quote begin
            let $x_ = $idx_, val=val*(one($rdx_)-$rdx_)
                $ex
            end
            let $x_ = $idx_+1, val=val*$rdx_
                $ex
            end
        end end
    end
    
    quote
        $(Expr(:meta, :inline))
        $(Expr(:meta, :propagate_inbounds))

        @nexprs $N i -> begin
            fdx_i = floor(I[i])
            idx_i = unsafe_trunc(Int, fdx_i)
            rdx_i = I[i] - fdx_i
        end
        
        $ex
    end
end
