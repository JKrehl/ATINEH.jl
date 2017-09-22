__precompile__()
module ATINEH

    using Base.Cartesian
    import Base.Cartesian: _nref, inlineanonymous

    function _nref(N::Int, A::Expr, ex)
        vars = [ inlineanonymous(ex,i) for i = 1:N ]
        Expr(:escape, Expr(:ref, A, vars...))
    end

    include("AffineTransforms.jl")
    include("IndexingModifiers.jl")
    include("ExteriorHandling.jl")
    include("Interpolation.jl")
    include("IndexAffineTransform.jl")
    include("IndexSupports.jl")
end
