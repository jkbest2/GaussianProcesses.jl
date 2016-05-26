# Rational Quadratic ARD Covariance Function 

@doc """
# Description
Constructor for the ARD Rational Quadratic kernel (covariance)

k(x,x') = σ²(1+(x-x')ᵀL⁻²(x-x')/2α)^{-α}, where L = diag(ℓ₁,ℓ₂,...)
# Arguments:
* `ll::Vector{Float64}`: Log of length scale ℓ
* `lσ::Float64`        : Log of the signal standard deviation σ
* `lα::Float64`        : Log of shape parameter α
""" ->
type RQArd <: Stationary
    ℓ2::Vector{Float64}      # Length scale 
    σ2::Float64              # Signal std
    α::Float64               # Shape parameter
    dim::Int                 # Number of hyperparameters
    RQArd(ll::Vector{Float64}, lσ::Float64, lα::Float64) = new(exp(2.0*ll), exp(2.0*lσ), exp(lα), size(ll,1)+2)
end

function set_params!(rq::RQArd, hyp::Vector{Float64})
    length(hyp) == rq.dim || throw(ArgumentError("Rational Quadratic ARD function has $(rq.dim) parameters"))
    rq.ℓ2 = exp(2.0*hyp[1:rq.dim-2])
    rq.σ2 = exp(2.0*hyp[rq.dim-1])
    rq.α = exp(hyp[rq.dim])
end

get_params(rq::RQArd) = [log(rq.ℓ2)/2.0; log(rq.σ2)/2.0; log(rq.α)]
get_param_names(rq::RQArd) = [get_param_names(rq.ℓ2, :ll); :lσ; :lα]
num_params(rq::RQArd) = rq.dim

metric(rq::RQArd) = WeightedSqEuclidean(1.0./(rq.ℓ2))
kern(rq::RQArd,r::Float64) = rq.σ2*(1+0.5*r/rq.α)^(-rq.α)
    

function grad_kern(rq::RQArd, x::Vector{Float64}, y::Vector{Float64})
    wdiff = ((x-y).^2)./rq.ℓ2
    dxy2  = sum(wdiff)
    part  = (1+0.5*dxy2/rq.α)

    g1   = rq.σ2*wdiff*part^(-rq.α-1)
    g2   = 2.0*rq.σ2*part^(-rq.α)
    g3   = rq.σ2*part^(-rq.α)*(0.5*dxy2/part-rq.α*log(part))*rq.α
    return [g1; g2; g3]
end

# function grad_stack!(stack::AbstractArray, X::Matrix{Float64}, rq::RQArd)
#     d = size(X,1)
#     R = distance(rq,X)
#     part  = (1+0.5*R/rq.α)
    
#     stack[:,:,d+1] = crossKern(X, rq)
#     ck = view(stack, :, :, d+1)

#     for i in 1:d
#         grad_ls = view(stack, :, :, i)
#         pairwise!(grad_ls, WeightedSqEuclidean([1.0/rq.ℓ2[i]]), view(X, i, :))
#         map!(*, grad_ls, grad_ls, ck./part)
#     end
#     stack[:,:, d+1] = 2.0 * ck
#     stack[:,:, d+2] = ck.*(0.5*R./part-rq.α*log(part))*rq.α
#     return stack
# end
