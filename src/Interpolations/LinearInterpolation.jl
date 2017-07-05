import Base: getindex, setindex!
import ATINEH:addindex!

export LinearInterpolation

struct LinearInterpolation <: AbstractIndexMap
end

@inline getindex(A::MappedArray_byMap{<:LinearInterpolation}, I::Vararg{Number}) = getindex(A, I)
@generated function getindex{N, IT<:NTuple{N, Number}}(A::MappedArray_byMap{<:LinearInterpolation}, I::IT)
    xs = ((Symbol("x_",i) for i in 1:N)...)
    ex = :(getindex(A.a, $(xs...)))
    preexs = Expr[]

    for i in 1:N
        x_, i_, r_ = xs[i], Symbol("i_",i), Symbol("r_",i)
        if IT.parameters[i] <: AbstractFloat
            push!(preexs, :($i_ = floor(Int, I[$i])), :($r_ = mod(I[$i], 1)))

            ex = quote
                +(let $x_ = $i_; (1-$r_)*$ex; end,
                    let $x_ = $i_+1; $r_*$ex; end)
            end
        else
            ex = quote
               let $x_ = I[$i]; $ex; end
            end
        end
    end

    quote
        $(Expr(:meta, :inline))
        let $(preexs...)
            $ex
        end
    end
end


@generated function setindex!{N}(A::MappedArray_byMap{<:LinearInterpolation}, val, I::Vararg{Number,N})
    throw(ArgumentError("setindex! is ill defined for linear interpolation"))
end

@inline addindex!(A::MappedArray_byMap{<:LinearInterpolation}, val, I::Vararg{Number}) = addindex!(A, val, I)
@generated function addindex!{N, IT<:NTuple{N, Number}}(A::MappedArray_byMap{<:LinearInterpolation}, val, I::IT)
    xs = ((Symbol("x_",i) for i in 1:N)...)
    ex = :(addindex!(A.a, val, $(xs...)))
    preexs = Expr[]

    for i in 1:N
        x_, i_, r_ = xs[i], Symbol("i_",i), Symbol("r_",i)
        if IT.parameters[i] <: AbstractFloat
            push!(preexs, :($i_ = floor(Int, I[$i])), :($r_ = mod(I[$i], 1)))

            ex = quote
                let $x_ = $i_, val=val*(1-$r_);
                    $ex
                end
                let $x_ = $i_+1, val=val*$r_;
                    $ex
                end
            end
        else
            ex = quote
               let $x_ = I[$i]; $ex; end
            end
        end
    end

    quote
        $(Expr(:meta, :inline))
        let $(preexs...)
            $ex
        end
        nothing
    end
end
