export LinearLatticeInterpolation

struct LinearLatticeInterpolation{N, A<:StaticMatrix{N, N}, DT} <: AbstractInterpolation
    matrix::A
    det::DT
    maxs::NTuple{N, Int}
    
    function LinearLatticeInterpolation(matrix::A) where {N, A<:StaticMatrix{N,N}}
        imat = inv(matrix)
        idet = det(imat)
        maxs = ntuple(i->unsafe_trunc(Int, 1+floor(sum(abs, matrix[i,:]))), Val{N})
        
        new{N,A,typeof(idet)}(imat, idet, maxs)
    end
end

LinearLatticeInterpolation(transform::AffineTransform) = LinearLatticeInterpolation(transform.matrix)
LinearLatticeInterpolation() = LinearLatticeInterpolation(AffineTransform{1}())

@implupdate LinearLatticeInterpolation transform x t::AffineTransform -> LinearLatticeInterpolation(t)

@generated function getindex(A::MappedArray{T,<:Any,<:Any,<:LinearLatticeInterpolation{N}}, I::Vararg{<:Number, N}) where {N,T}
    ex = :(@ncall $N getindex A.array i->x_i)
    for i in 1:N
        x_ = Symbol("x_", i)
        idx_ = Symbol("idx_", i)
        rdx_ = Symbol("rdx_", i)
        
        ex = quote begin
            local r1 = let $x_ = $idx_
               (one($T)-$rdx_) * $ex
            end
            local r2 = let $x_ = $idx_+1
                $rdx_ * $ex
            end
            r1+r2
        end end
    end
    
    quote
        $(Expr(:meta, :inline))
        $(Expr(:meta, :propagate_inbounds))
        
        @nexprs $N i -> begin
            fdx_i = floor(I[i])
            idx_i = unsafe_trunc(Int, fdx_i)
            rdx_i = $T(I[i] - fdx_i)
        end
        
        A.map.det * $ex
    end
end

function setindex!(::MappedArray_byMap{<:LinearLatticeInterpolation}, _, ::Vararg{<:Number})
    throw(ArgumentError("setindex! is ill defined for LinearLatticeInterpolation"))
    nothing
end

@generated function addindex!(A::MappedArray{T,<:Any,<:Any,<:LinearLatticeInterpolation{N}}, val, I::Vararg{<:Number, N}) where {N,T}

    ex = quote
        dv = imat*SVector(@ntuple($N, i -> rdx_i + j_i))
        idv = @ntuple $N i -> 1-abs(dv[i])
        if @nall $N i -> idv[i] < 0
            sval = *(idv..., mval)
            @ncall $N addindex! A.array sval i -> idx_i - j_i
        end
    end

    for i in 1:N
        x_ = Symbol(:x_, i)
        j_ = Symbol(:j_, i)
        idx_ = Symbol(:idx_, i)
        max_ = Symbol(:max_, i)
        ex = quote
            for $j_ in -$max_:$max_
                #let #=dv = @ntuple($N, k -> fma(j, imat[k, $i], dv[k])),=# $x_ = $idx_ - $j_
                    $ex
                #end
            end
        end
    end
    
    quote
        $(Expr(:meta, :inline))
        $(Expr(:meta, :propagate_inbounds))

        imat = A.map.matrix
        mval = A.map.det * val

        @inbounds @nexprs $N i -> begin
            fdx_i = floor(I[i])
            idx_i = unsafe_trunc(Int, fdx_i)
            rdx_i = $T(I[i] - fdx_i)
            max_i = A.map.maxs[i]
        end

        #dv = imat*SVector(@ntuple($N, i->rdx_i))

        $ex
    end
end
