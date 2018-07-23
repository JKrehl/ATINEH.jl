__precompile__()
module ATINEH

using Base.Cartesian
import Base.Cartesian.inlineanonymous

export @update, @implupdate, update

function _nref(N::Int, A::Expr, ex)
    vars = [ inlineanonymous(ex,i) for i = 1:N ]
    Expr(:escape, Expr(:ref, A, vars...))
end

function update end

"""
`@update(x, name::Symbol, ex)` 
will call the `update function` for `x` and `name` with the return of the value of `ex`
thereby, the value `x` can be used in `ex`
"""
macro update(x, name::Symbol, ex)
    :(update($(esc(x)), $(Val{name}()), $(esc(ex))))
end

"""
@implupdate implements an update function

two syntaxes are possible:
    `@implupdate(T, name::Symbol, object::Symbol, ex::Expr)` defines `update` for type `T` by evaluating the annonymous function `ex` where the `object` is a handle of the updatetee
    `@implupdate(T, name::Symbol)' a gemeric syntax for types with constructors taking all fields in order as arguments (that is not tested in depth) the fields are taken from the updatetee and the field of name `name` is replaced
"""
macro implupdate(T, name::Symbol, object::Symbol, ex::Expr)
    @assert ex.head == :->
    eT = Core.eval(__module__, T)
    callsym = ex.args[1] isa Expr && ex.args[1].head == :tuple ? (ex.args[1].args...,) : (ex.args[1],)
    quote
        @inline update(x::$eT, ::$(Val{name}), $(callsym...)) = $(ex.args[2])
    end |> esc
end

macro implupdate(T, name::Symbol)
    eT = Core.eval(__module__, T)
    @assert !isempty(methods(eT, map(nm->fieldtype(eT, nm), fieldnames(eT))))
    ex = Expr(:call, eT, [fn==name ? name : :(x.$fn) for fn in fieldnames(eT)]...)
    quote
        @inline update(x::$eT, ::$(Val{name}), $name) = $ex
    end |> esc
end

include("AffineTransforms.jl")
include("IndexingModifiers.jl")
include("ExteriorHandling.jl")
include("Interpolation/Interpolation.jl")
include("IndexAffineTransform.jl")
include("IndexSupports.jl")

end
