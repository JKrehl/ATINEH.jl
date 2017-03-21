import Base: getindex, setindex!
import ATINEH:NAbstractArray, addindex!

export LinearInterpolation

struct LinearInterpolation{N} <: AbstractIndexTransform{N}
end

@generated function getindex{N, IT<:NTuple{N,Number}}(A::NAbstractArray{N}, imc::IndexTransformChain{N}, ::LinearInterpolation{N}, I::IT)
    xs = ((Symbol("x_",i) for i in 1:N)...)
    ex = :(getindex(A, imc, $(xs...)))
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

@generated function setindex!{N, IT<:NTuple{N,Number}}(A::NAbstractArray{N}, val, imc::IndexTransformChain{N}, ::LinearInterpolation{N}, I::IT)
    throw(ArgumentError("setindex! is ill defined for linear interpolation"))
end

@generated function addindex!{N, IT<:NTuple{N,Number}}(A::NAbstractArray{N}, val, imc::IndexTransformChain{N}, ::LinearInterpolation{N}, I::IT)
    xs = ((Symbol("x_",i) for i in 1:N)...)
    ex = :(addindex!(A, val, imc, $(xs...)))
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
    end
end
