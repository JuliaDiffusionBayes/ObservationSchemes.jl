"""
    StartingPtPrior{T}

Types inheriting from the abstract type `StartingPtPrior` indicate the prior
that is put on the starting point of the observed path of some stochastic
process. `T` denotes the DataType of the starting point.
"""
abstract type StartingPtPrior{T} end

@doc raw"""
    Base.rand(G::StartingPtPrior, [z, ρ=0.0])

Sample a new starting point according to its prior distribution. An
implementation with arguments `z`, `ρ` implements a preconditioned
Crank-Nicolson scheme with memory parameter `ρ` and a current **non-centered
variable** `z`. `z` is also referred to as the **driving noise**.
"""
Base.rand(G::StartingPtPrior, z, ρ=0.0) = error("Not Implemented")
Base.rand(G::StartingPtPrior) = error("Not Implemented")


"""
    start_pt(z, G::StartingPtPrior, P)

Compute a new starting point from the white noise for a given posterior
distribution obtained from combining prior `G` and the likelihood encoded by the
object `P`.
"""
start_pt(z, G::StartingPtPrior, P) = error("Not Implemented")

"""
    start_pt(z, G::StartingPtPrior)

Compute a new starting point from the white noise for a given prior
distribution `G`
"""
start_pt(z, G::StartingPtPrior) = error("Not Implemented")


"""
    inv_start_pt(y, G::StartingPtPrior, P)

Compute the driving noise that is needed to obtain starting point `y` under
prior `G` and the likelihood in `P`
"""
inv_start_pt(y, G::StartingPtPrior, P) = error("Not Implemented")


"""
    logpdf(G::StartingPtPrior, y)

log-probability density function evaluated at `y` of a prior distribution `G`
"""
Distributions.logpdf(G::StartingPtPrior, y) = error("Not Implemented")



#===============================================================================
                            Struct definitions
===============================================================================#

"""
    struct KnownStartingPt{T} <: StartingPtPrior{T}
        y::T
    end

Indicates that the starting point is known and stores its value in `y`

    KnownStartingPt(y::T) where T

Base constructor.
"""
struct KnownStartingPt{T} <: StartingPtPrior{T}
    y::T
    KnownStartingPt(y::T) where T = new{T}(y)
end

"""
    struct GsnStartingPt{T,S,TM} <: StartingPtPrior{T} where {S}
        μ::T
        Σ::S
        Λ::S
        μ₀::T
        Σ₀::UniformScaling
    end

Indicates that the starting point is equipped with a Gaussian prior with
mean `μ` and covariance matrix `Σ` (and pre-computed precision `Λ`:=`Σ`⁻¹).
Sampling is always done via non-centred parametrization, by sampling white noise
`z` according to Gaussian with zero mean and identity covariance: `μ₀` and `Σ₀`,
and then transforming `z` to a variable with mean and covariance `μ` and `Σ`.

    GsnStartingPt(μ::T, Σ::S)

Base constructor. It initialises the mean `μ` and covariance `Σ` parameters and
`Λ` is set according to `Λ`:=`Σ`⁻¹.
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
    GsnStartingPt{T,typeof(Σ),:mutable}(
        μ, Σ, inv(Σ), zeros(eltype(T), length(μ)), I
    )
end

function GsnStartingPt(μ::T, Σ, ::Val{false}) where T
    typeof(Σ) <: SVector && length(Σ) == 1 && (Σ = SMatrix{1,1}(Σ))
    ismutable(Σ)::Val{false}
    @assert size(Σ,1) == size(Σ,2) == length(μ)
    GsnStartingPt{T,typeof(Σ),:immutable}(μ, Σ, inv(Σ), zero(T), I)
end

#===============================================================================
                Sampling a starting point according to a prior
===============================================================================#

"""
    rand([rng::Random.AbstractRNG], G::GsnStartingPt, z, ρ=0.0)

Sample new white noise using Crank-Nicolson scheme with memory parameter `ρ` and
a previous value of the white noise stored inside object `G`
"""
function Base.rand(rng::Random.AbstractRNG, G::GsnStartingPt, z, ρ=0.0)
    zᵒ = rand(rng, Gaussian(G.μ₀, G.Σ₀))
    sqrt(1-ρ)*zᵒ + sqrt(ρ)*z # preconditioned Crank-Nicolson
end

Base.rand(G::GsnStartingPt, z, ρ=0.0) = rand(Random.GLOBAL_RNG, G, z, ρ)


"""
    rand([rng::Random.AbstractRNG], G::GsnStartingPt)

Sample new starting point according to its prior distribution.
"""
function Base.rand(rng::Random.AbstractRNG, G::GsnStartingPt)
    rand(rng, Gaussian(G.μ, G.Σ))
end

Base.rand(G::GsnStartingPt) = rand(Random.GLOBAL_RNG, Gaussian(G.μ, G.Σ))

"""
    rand([rng::Random.AbstractRNG], G::KnownStartingPt, args...)

Starting point is known. Nothing can be sampled. Returning known starting point.
"""
function Base.rand(rng::Random.AbstractRNG, G::KnownStartingPt, args...)
    rand(Random.GLOBAL_RNG, G, args...)
end

Base.rand(G::KnownStartingPt, args...) = G.y

#===============================================================================
                Compute the starting point from random seed
===============================================================================#

"""
    start_pt(z, G::GsnStartingPt, P)

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
    start_pt(z, G::GsnStartingPt)

Compute a new starting point from the white noise for a given prior
distribution `G`
"""
start_pt(z, G::GsnStartingPt) = unwhiten(G.Σ, z) + G.μ

"""
    start_pt(z, G::KnownStartingPt, P)

Return starting point
"""
start_pt(z, G::KnownStartingPt, P) = G.y

#TODO check if this is needed
"""
    start_pt(G::KnownStartingPt, P)

Return starting point
"""
start_pt(G::KnownStartingPt, P) = G.y

#===============================================================================
                Compute the random seed from the starting point
===============================================================================#

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

#===============================================================================
                            compute logpdf
===============================================================================#

"""
    logpdf(::KnownStartingPt, y)

Nothing to do so long as `y` is equal to the known starting point inside `G`
"""
function Distributions.logpdf(G::KnownStartingPt, y)
    (G.y == y) ? 0.0 : error("Starting point is known, but a different value ",
                             "was passed to logpdf.")
end


"""
    logpdf(G::GsnStartingPt, y)

log-probability density function evaluated at `y` of a prior distribution `G`
"""
Distributions.logpdf(G::GsnStartingPt, y) = logpdf(Gaussian(G.μ, G.Σ), y)
