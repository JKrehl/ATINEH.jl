export VolumetricInterpolation

struct VolumetricInterpolation <: AbstractIndexingModifier
    S::Int
    D::Int
    VolumetricInterpolation(S::Int=32, D::Int=8) = new(S,D)
end

@generated function flatcube{M,N,MT,ST}(trafo::AffineTransform{M,N,MT,ST}, S, D)
    T = promote_type(eltype(MT), eltype(ST), Bool)
    quote
        bins_max = @ntuple $M i -> ceil(Int, sum(abs, trafo.matrix[i,:]))
        bins_num = @ntuple $M i -> 1+2*bins_max[i]
        bins_idims = @ntuple $M i -> -bins_max[i]:bins_max[i]
        bins_dims = @ntuple $M i -> (-bins_max[i]):1/D:(bins_max[i])
        bins_offs = @ntuple $M i -> bins_max[i]*D+1
        Dtrafo = unscale(bins_dims...)*AffineTransform(trafo.matrix)

        bins = zeros($T, map(length, bins_dims))
        @nloops $N x i->((1-S)/2:(S-1)/2)/S begin
            addindex!(bins, true, NearestInterpolation(), IndexAffineTransform(Dtrafo), @ntuple($N, i->x_i)...)
        end
        bins .*= inv(S^$N)
        ebins = MappedArray(bins, ConstantExterior())

        weights = Array{Array{$T, $M}, $M}(@ntuple $M i->D)
        @nloops $M d i->1:D begin
            iw = zeros($T, bins_num)
            @nloops $M b i->-bins_max[i]:bins_max[i] begin
                @nloops $M x i->1:D begin
                    @nref($M, iw, i->bins_max[i]-b_i+1) += @nref($M, ebins, i -> bins_offs[i] + (d_i-1) + (b_i)*D + (x_i-div(D,2)-1))
                end
            end
            @nref($M, weights, i->d_i) = iw
        end

        submap_type = SArray{Tuple{bins_num...}, $T, $M, prod(bins_num)}
        SArray{Tuple{@ntuple($M,i->D)...}, submap_type}(weights), @ntuple $M i -> bins_max[i]+1
    end
end
