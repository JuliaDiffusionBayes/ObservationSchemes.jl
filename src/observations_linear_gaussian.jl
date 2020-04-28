#===============================================================================

        Linear transformation of the underlying process, disturbed
        by Gaussian noise

===============================================================================#
"""
    struct LinearGsnObs{Tag,D,T,FPT,S,R,K} <: Observation{D,T}
        L::S
        μ::T
        Σ::R
        obs::T
        t::Float64
        full_obs::Bool
        θ::Vector{K}
    end

Observation of the underlying process that is of the form:
LX+ξ, where ξ∼N(μ,Σ) and L,Σ and μ are respectively matrices and a vector of
appropriate dimensions. `FPT` stores information about first-passage times.
`full_obs` is an indicator for whether it is a full observation of the process
(as it grants the use of Markov Property). `θ` is a container that may contain
parameters that enter `L`, `μ`, `Σ` and `Tag` is a disambiguation flag used at
compile time or for multiple dispatch to differentiate between different
observation types.
"""
struct LinearGsnObs{Tag,D,T,FPT,S,R,K} <: Observation{D,T}
    L::S
    μ::T
    Σ::R
    obs::T
    t::Float64
    full_obs::Bool
    θ::Vector{K}

    function LinearGsnObs(
            t, obs::T, L::S, Σ::R, μ::T, fpt::FPT, full_obs, θ::Vector{K}, Tag,
        ) where {T,S,R,FPT,K}
        D = length(obs)
        new{Tag,D,T,FPT,S,R,K}(L, μ, Σ, obs, t, full_obs, θ)
    end
end

function LinearGsnObs(t, obs; kwargs...)
    LinearGsnObs(ismutable(obs), t, obs; kwargs...)
end

function LinearGsnObs(
        ::Val{true},
        t,
        obs::T;
        L::S=Diagonal(repeat([one(eltype(T))], length(obs))),
        Σ::R=Diagonal(repeat([one(eltype(T))], length(obs)))*1e-11,
        μ::T=zeros(eltype(T),length(obs)),
        fpt::FPT=NoFirstPassageTimes(),
        full_obs=false,
        Tag=0,
        θ=[],
    ) where {T,S,R,FPT}
    @assert length(θ) == 0 || Tag > 0
    LinearGsnObs(t, obs, L, Σ, μ, fpt, full_obs, θ, Tag)
end

function LinearGsnObs(
        ::Val{false},
        t,
        obs::T;
        L::S=SDiagonal{length(obs)}(I),
        Σ::R=SDiagonal{length(obs)}(I)*1e-11,
        μ::T=zero(T),
        fpt::FPT=NoFirstPassageTimes(),
        full_obs=false,
        Tag=0,
        θ=[],
    ) where {T,S,R,FPT}
    @assert length(θ) == 0 || Tag > 0
    LinearGsnObs(t, obs, L, Σ, μ, fpt, full_obs, θ, Tag)
end

"""
    fpt_info(::LinearGsnObs{D,T,Tag,FPT}) where {D,T,Tag,FPT}

Return information about first-passage times
"""
fpt_info(::LinearGsnObs{Tag,D,T,FPT}) where {Tag,D,T,FPT} = FPT

get_tag(::LinearGsnObs{Tag}) where Tag = Tag
#=
function show(obs::LinearGsnObs)
    L, μ, Σ, v = L(obs), μ(obs), Σ(obs), ν(obs)
    t, full_obs = obs.t, obs.full_obs
    θ = parameters(obs)
    parametric_type = get_tag(obs) > 0
    L_size = size(L)
    println(repeat("⏤", 40 ))
    println(
        "|Observation `v = Lx+ξ`, where `L` is a $L_size-matrix, `x` is a ",
        "state of the stochastic process and `ξ`∼N(μ,Σ)."
    )
    println("|...")
    println("|| v: $v (observation),\n|| \t→ typeof(v): ", typeof(v),",")
    println("|| made at time $t.")
    println("|...")
    println("|L: $L,\n|\t→ typeof(L): ", typeof(L))
    println("|μ: $μ,\n|\t→ typeof(μ): ", typeof(μ))
    println("|Σ: $Σ,\n|\t→ typeof(Σ): ", typeof(Σ))
    println("|...")
    println("|This is ", (full_obs ? "" : "NOT ") , "an exact observation.")
    println("|...")
    println(
        "|It ",
        parametric_type ?
        "depends on additional parameters, which are set to: $θ." :
        "does not depend on any additional parameters."
    )
    println("|...")
    show(fpt_info(obs); prepend="|")
    println(repeat("⋆ ", 10))
end
=#

function Base.summary(io::IO, obs::LinearGsnObs)
    _L, _μ, _Σ, v = L(obs), μ(obs), Σ(obs), ν(obs)
    t, full_obs = obs.t, obs.full_obs
    θ = parameters(obs)
    parametric_type = get_tag(obs) > 0
    L_size = size(_L)
    println(io, repeat("⏤", 40 ))
    println(
        io,
        "|Observation `v = Lx+ξ`, where `L` is a $L_size-matrix, `x` is a ",
        "state of the stochastic process and `ξ`∼N(μ,Σ)."
    )
    println(io, "|...")
    println(io, "|| ν: $v (observation),\n|| \t→ typeof(ν): ", typeof(v),",")
    println(io, "|| made at time $t.")
    println(io, "|...")
    println(io, "|L: $_L,\n|\t→ typeof(L): ", typeof(_L))
    println(io, "|μ: $_μ,\n|\t→ typeof(μ): ", typeof(_μ))
    println(io, "|Σ: $_Σ,\n|\t→ typeof(Σ): ", typeof(_Σ))
    println(io, "|...")
    println(io, "|This is ", (full_obs ? "" : "NOT ") , "an exact observation.")
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
    println(io, repeat("⋆ ", 10))
end

Base.summary(o::LinearGsnObs) = summary(Base.stdout, o)

L(o::LinearGsnObs) = o.L
μ(o::LinearGsnObs) = o.μ
Σ(o::LinearGsnObs) = o.Σ
Λ(o::LinearGsnObs) = inv(o.Σ)
ν(o::LinearGsnObs) = o.obs
obs = ν
clone(o::LinearGsnObs{0}, args...) = o
update_params!(o::LinearGsnObs{0}, new_params...) = o

function update_params!(o::LinearGsnObs, new_params::AbstractArray)
    update_params!(o, new_params...)
end
function update_params!(o::LinearGsnObs, new_params...)
    @assert length(new_params) == length(o.θ)
    o.θ .= new_params
    o
end

parameter_names(o::LinearGsnObs) = tuple()
parameters(o::LinearGsnObs) = tuple(o.θ...)
