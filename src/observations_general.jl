@doc raw"""
    struct GeneralObs{Tag,D,T,FPT,K,Tlo,Tg,Td} <: Observation{D,T}
        lin_obs::Tlo
        g::Tg
        dist::Td
        obs::T
        t::Float64
        θ::Vector{K}
    end

General observation of the underlying process that is of the form:
```math
g(x)+ξ,
```
where $ξ$ is distributed according to `dist`, $g$ (corresponding to passed `g`)
is a function specified externally, `obs` is the observation made at time `t`,
`θ` is a container that may contain parameters and `lin_obs` is the
approximation to this general observation scheme via the linearization with
Gaussian noise.

    GeneralObs(
        t,
        obs,
        linearization;
        dist=_default_dist(obs),
        g=identity,
        fpt=NoFirstPassageTimes(),
        Tag=0,
        θ=[],
    )

Base constructor.
"""
struct GeneralObs{Tag,D,T,FPT,K,Tlo,Tg,Td} <: Observation{D,T}
    lin_obs::Tlo
    g::Tg
    dist::Td
    obs::T
    t::Float64
    θ::Vector{K}

    function GeneralObs(
            t, obs::T, lin_obs::Tlo, fpt::FPT, g::Tg, dist::Td, θ::Vector{K}, Tag,
        ) where {T,Tlo,FPT,Tg,Td,K}
        D = length(obs)
        new{Tag,D,T,FPT,K,Tlo,Tg,Td}(lin_obs, g, dist, obs, t, θ)
    end
end

function GeneralObs(
        t,
        obs,
        linearization;
        dist=_default_dist(obs),
        g=identity,
        fpt=NoFirstPassageTimes(),
        Tag=0,
        θ=[],
    )
    D = length(obs)
    GeneralObs(t, obs, linearization, fpt, g, dist, θ, Tag)
end

_default_dist(obs) = GaussianDistribtuions(_default_μ(obs), _default_Σ(obs))

fpt_info(::GeneralObs{Tag,D,T,FPT}) where {Tag,D,T,FPT} = FPT
get_tag(::GeneralObs{Tag}) where Tag = Tag

function Base.summary(io::IO, obs::GeneralObs)
    v, t = ν(obs), obs.t
    θ = parameters(obs)
    parametric_type = get_tag(obs) > 0
    println(io, repeat("⏤", 40 ))
    println(
        io,
        "|Observation `v = g(x)+ξ`, where `g` is an operator defined by a ",
        "function ", typeof(obs.g), ", and `ξ` is a random variable given by",
        typeof(obs.dist), "."
    )
    println(io, "|...")
    println(io, "|| ν: $v (observation),\n|| \t→ typeof(ν): ", typeof(v),",")
    println(io, "|| made at time $t.")
    println(io, "|...")
    println(io, "|This is NOT an exact observation.")
    println(io, "|...")
    println(
        io,
        "|It ",
        parametric_type ?
        "depends on additional parameters, which are set to: $θ." :
        "does not depend on any additional parameters."
    )
    println(io, "|...")
    _summary_fpt(io, fpt_info(obs); prepend="|")
    println(io, "|...")
    println(
        io,
        "|To inspect the linearized approximation to this observation ",
        "scheme please type in:"
    )
    println(io, "|\tsummary(<name-of-the-variable>.lin_obs)")
    println(io, "|and hit ENTER.")
    println(io, repeat("⋆ ", 10))
end


function Base.rand(rng::Random.AbstractRNG, o::GeneralObs, x)
    error("Not Implemented")
end

Base.rand(o::GeneralObs, x) = rand(Random.GLOBAL_RNG, o, x)
