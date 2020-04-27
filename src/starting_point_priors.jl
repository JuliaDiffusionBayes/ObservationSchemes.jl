"""
    StartingPtPrior

Types inheriting from the abstract type `StartingPtPrior` indicate the prior
that is put on the starting point of the observed path following the dynamics
of some stochastic differential equation.
"""
abstract type StartingPtPrior{T} end

"""
    KnownStartingPt{T} <: StartingPtPrior

Indicates that the starting point is known and stores its value in `y`
"""
struct KnownStartingPt{T} <: StartingPtPrior{T}
    y::T
    KnownStartingPt(y::T) where T = new{T}(y)
end

"""
    GsnStartingPt{T,S} <: StartingPtPrior

Indicates that the starting point is equipped with a Gaussian prior with
mean `μ` and covariance matrix `Σ`. It also stores the most recently sampled
white noise `z` used to compute the starting point and a precision matrix
`Λ`:=`Σ`⁻¹. `μ₀` and `Σ₀` are the mean and covariance of the white noise

    GsnStartingPt(μ::T, Σ::S)

Base constructor. It initialises the mean `μ` and covariance `Σ` parameters and
`Λ` is set according to `Λ`:=`Σ`⁻¹
"""
struct GsnStartingPt{T,S,TM} <: StartingPtPrior{T} where {S}
    μ::T
    Σ::S
    Λ::S
    μ₀::T
    Σ₀::UniformScaling

    GsnStartingPt{T,S,TM}(
        μ::T,
        Σ::S,
        Λ::S,
        μ₀::T,
        Σ₀::UniformScaling
    ) where {T,S,TM} = new{T,S,TM}(μ, Σ, Λ, μ₀, Σ₀)
end

GsnStartingPt(μ, Σ) = GsnStartingPt(μ, Σ, ismutable(μ))

function GsnStartingPt(μ::T, Σ, ::Val{true}) where T
    typeof(Σ) <: Vector && length(Σ) == 1 && (Σ = reshape(Σ, 1, 1))
    ismutable(Σ)::Val{true}
    @assert size(Σ,1) == size(Σ,2) == length(μ)
    GsnStartingPt{T,typeof(Σ),:mutable}(μ, Σ, inv(Σ), zeros(eltype(T), length(μ)), I)
end

function GsnStartingPt(μ::T, Σ, ::Val{false}) where T
    typeof(Σ) <: SVector && length(Σ) == 1 && (Σ = SMatrix{1,1}(Σ))
    ismutable(Σ)::Val{false}
    @assert size(Σ,1) == size(Σ,2) == length(μ)
    GsnStartingPt{T,typeof(Σ),:immutable}(μ, Σ, inv(Σ), zero(T), I)
end


"""
    rand(G::GsnStartingPt, ρ)

Sample new white noise using Crank-Nicolson scheme with memory parameter `ρ` and
a previous value of the white noise stored inside object `G`
"""
rand(G::GsnStartingPt) = rand(Gaussian(G.μ, G.Σ))

function rand(G::GsnStartingPt, z, ρ=0.0)
    zᵒ = rand(Gaussian(G.μ₀, G.Σ₀))
    sqrt(1-ρ)*zᵒ + sqrt(ρ)*z # preconditioned Crank-Nicolson
end

"""
    rand(G::KnownStartingPt, ::Any)

If starting point is known then nothing can be sampled, using convention of
returning the known startin point
"""
rand(G::KnownStartingPt, ::Any=nothing, ::Any=nothing) = G.y


"""
    start_pt(G::GsnStartingPt, P)

Compute a new starting point from the white noise for a given posterior
distribution obtained from combining prior `G` and the likelihood encoded by the
object `P`.
"""
function start_pt(z, G::GsnStartingPt, P)
    μ_post = (P.H[1] + G.Λ) \ (P.Hν[1] + G.Λ * G.μ)
    Σ_post = inv(P.H[1] + G.Λ)
    Σ_post = 0.5 * (Σ_post + Σ_post') # remove numerical inaccuracies
    unwhiten(Σ_post, z) + μ_post
end

"""
    start_pt(G::GsnStartingPt, P)

Compute a new starting point from the white noise for a given prior
distribution `G`
"""
start_pt(z, G::GsnStartingPt) = unwhiten(G.Σ, z) + G.μ

"""
    start_pt(G::KnownStartingPt, P)

Return starting point
"""
start_pt(z, G::KnownStartingPt, P) = G.y

"""
    start_pt(G::KnownStartingPt, P)

Return starting point
"""
start_pt(z, G::KnownStartingPt) = G.y

"""
    inv_start_pt(y, G::GsnStartingPt, P)

Compute the driving noise that is needed to obtain starting point `y` under
prior `G` and the likelihood in `P`
"""
function inv_start_pt(y, G::GsnStartingPt, P)
    μ_post = (P.H[1] + G.Λ) \ (P.Hν[1] + G.Λ * G.μ)
    Σ_post = inv(P.H[1] + G.Λ)
    Σ_post = 0.5 * (Σ_post + Σ_post')
    try
        whiten(Σ_post, y-μ_post)
    catch e
        print("incorrect matrix: ", Σ_post, "\n\n")
    end
    whiten(Σ_post, y-μ_post)
end

"""
    inv_start_pt(y, G::KnownStartingPt, P)

Starting point known, no need for dealing with white noise, use convention of
returning `y`
"""
inv_start_pt(y, G::KnownStartingPt, P) = y

"""
    logpdf(::KnownStartingPt, y)

Nothing to do so long as `y` is equal to the known starting point inside `G`
"""
function logpdf(G::KnownStartingPt, y)
    (G.y == y) ? 0.0 : error("Starting point is known, but a different value ",
                             "was passed to logpdf.")
end


"""
    logpdf(::GsnStartingPt, y)

log-probability density function evaluated at `y` of a prior distribution `G`
"""
logpdf(G::GsnStartingPt, y) = logpdf(Gaussian(G.μ, G.Σ), y)
