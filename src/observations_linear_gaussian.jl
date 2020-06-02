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
struct LinearGsnObs{Tag,D,T,FPT,TL,Tμ,TΣ,K} <: Observation{D,T}
    L::TL
    μ::Tμ
    Σ::TΣ
    obs::T
    t::Float64
    full_obs::Bool
    θ::Vector{K}

    function LinearGsnObs(
            t, obs::T, L::TL, Σ::TΣ, μ::Tμ, fpt::FPT, full_obs, θ::Vector{K}, Tag,
        ) where {T,TL,TΣ,Tμ,FPT,K}
        D = length(obs)
        new{Tag,D,T,FPT,TL,Tμ,TΣ,K}(L, μ, Σ, obs, t, full_obs, θ)
    end
end

_default_L(obs) = _default_L(obs, ismutable(obs))
_default_L(obs::T, ::Val{true}) where T = Diagonal(repeat([one(eltype(T))], length(obs)))
_default_L(obs::T, ::Val{false}) where T = SDiagonal{length(obs)}(I)

_default_Σ(obs, ϵ=1e-11) = _default_Σ(obs, ismutable(obs), ϵ)
_default_Σ(obs::T, ::Val{true}, ϵ=1e-11) where T = Diagonal(repeat([one(eltype(T))], length(obs)))*ϵ
_default_Σ(obs::T, ::Val{false}, ϵ=1e-11) where T = SDiagonal{length(obs)}(I)*ϵ

_default_μ(obs) = _default_μ(obs, ismutable(obs))
_default_μ(obs::T, ::Val{true}) where T = zeros(eltype(T),length(obs))
_default_μ(obs::T, ::Val{false}) where T = zero(T)

function LinearGsnObs(
        t,
        obs::T;
        L=_default_L(obs),
        Σ=_default_Σ(obs),
        μ=_default_μ(obs),
        fpt=NoFirstPassageTimes(),
        full_obs=false,
        Tag=0,
        θ=[],
    ) where T
    @assert length(θ) == 0 || Tag > 0
    LinearGsnObs(t, obs, L, Σ, μ, fpt, full_obs, θ, Tag)
end

"""
    fpt_info(::LinearGsnObs{D,T,Tag,FPT}) where {D,T,Tag,FPT}

Return information about first-passage times
"""
fpt_info(::LinearGsnObs{Tag,D,T,FPT}) where {Tag,D,T,FPT} = FPT

get_tag(::LinearGsnObs{Tag}) where Tag = Tag

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

Base.summary(o::Observation) = summary(Base.stdout, o)

"""
    L(o::LinearGsnObs)

Return matrix L from the observation scheme ν = Lx+ξ, where ξ∼N(μ,Σ)
"""
L(o::LinearGsnObs) = o.L

"""
    μ(o::LinearGsnObs)

Return vector μ from the observation scheme ν = Lx+ξ, where ξ∼N(μ,Σ)
"""
μ(o::LinearGsnObs) = o.μ

"""
    Σ(o::LinearGsnObs)

Return matrix Σ from the observation scheme ν = Lx+ξ, where ξ∼N(μ,Σ)
"""
Σ(o::LinearGsnObs) = o.Σ

"""
    Λ(o::LinearGsnObs)

Return matrix Λ:=Σ⁻¹ from the observation scheme ν = Lx+ξ, where ξ∼N(μ,Σ)
"""
Λ(o::LinearGsnObs) = inv(o.Σ)

"""
    ν(o::Observation)

Return the observation
"""
ν(o::Observation) = o.obs

"""
    obs(o::Observation)

Alias to ν. Return the observation.
"""
const obs = ν


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

var_parameter_pos(o::Observation) = tuple()
parameters(o::Observation) = tuple(o.θ...)
