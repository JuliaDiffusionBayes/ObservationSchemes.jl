# [Get started](@id get_started)
***

## Installation
---------------------------------
The package is not registered yet. To install it write:
```julia
] add https://github.com/JuliaDiffusionBayes/ObservationSchemes.jl
```

## A single observation
---------------------
To define a single observation collected according to
```math
V_t = LX_t+ξ,\quad ξ ∼ N(μ,Σ),
```
use `LinearGsnObs`, for instance
```julia
ν = [1.0, 2.0, 3.0]
t = 2.0
L = [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0]
Σ = Diagonal([1.0, 1.0, 1e-11])
obs = LinearGsnObs(t, ν; L = L, Σ = Σ) # μ defaults to 0
```
To view some summary information call:
```julia
julia> summary(obs)
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (3, 4)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [1.0, 2.0, 3.0] (observation),
||  → typeof(ν): Array{Float64,1},
|| made at time 2.0.
|...
|L: [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0],
|   → typeof(L): Array{Float64,2}
|μ: [0.0, 0.0, 0.0],
|   → typeof(μ): Array{Float64,1}
|Σ: [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0e-11],
|   → typeof(Σ): Diagonal{Float64,Array{Float64,1}}
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```

For a general observation scheme:
```math
V_t = g(X_t) + ξ,\quad ξ ∼ Ξ
```
you may use `GeneralObs` instead of `LinearGsnObs`, but you must provide the function $$g$$, the law $$\Xi$$ (and an approximation via `LinearGsnObs` if you wish to use it with other packages in [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes)).

Additionally, first passage time observations are supported.

## Multiple observations
-----------------------
To define multiple observations at once define a list of observation formats in which the data was collected:
```julia
# type 1
t, v = 1.0, [1.0, 2.0, 3.0] # dummy values, only their DataTypes matter
obs = LinearGsnObs(t, v; full_obs=true)

# type 2, i.e. another observation scheme:
t, v = 1.0, [1.0]
obs2 = LinearGsnObs(t, v; L=[1.0 0.0 0.0;], Σ = reshape([1.0], (1,1)))

# data defined externally:
tt, xx = ...

# template of an observation scheme in pattern: obs, obs2, obs, obs2, obs, ...
obs_scheme = ObsScheme(obs, obs2; pattern=[1,2])

# decorate the data
observs = load_data(obs_scheme, tt, xx)
```
You can even collect your data directly from the simulated trajectory using `ObsScheme`:
```julia
# simulate some data
using DiffusionDefinition
@load_diffusion Lorenz
θ = [10.0, 28.0, 8.0/3.0, 1.0]
P = Lorenz(θ...)
tt, y1 = 0.0:0.001:10.0, @SVector [-10.0, -10.0, 25.0]
X = rand(P, tt, y1)

# collect the data and decorate
observs = collect(
    obs_scheme, X,
    1000, # 1 in every 1000 points collected
    true, # omit the starting pt
)
```
Inspecting the first two elements of `observs` reveals:
```julia
julia> summary(observs[1])
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (3, 3)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [-6.973713465241107, -7.078798675212648, 25.333374615535917] (observation),
||  → typeof(ν): Array{Float64,1},
|| made at time 1.0.
|...
|L: [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0],
|   → typeof(L): Diagonal{Float64,Array{Float64,1}}
|μ: [0.0, 0.0, 0.0],
|   → typeof(μ): Array{Float64,1}
|Σ: [1.0e-11 0.0 0.0; 0.0 1.0e-11 0.0; 0.0 0.0 1.0e-11],
|   → typeof(Σ): Diagonal{Float64,Array{Float64,1}}
|...
|This is an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆

julia> summary(observs[2])
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (1, 3)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [-8.536161659220804] (observation),
||  → typeof(ν): Array{Float64,1},
|| made at time 2.0.
|...
|L: [1.0 0.0 0.0],
|   → typeof(L): Array{Float64,2}
|μ: [0.0],
|   → typeof(μ): Array{Float64,1}
|Σ: [1.0],
|   → typeof(Σ): Array{Float64,2}
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```
The decorated observations of a trajectory may now be put inside a container that collects observations of multiple trajectories:
```julia
all_obs = AllObservations()
add_recording!(
    all_obs,
    (
        P = P, # this is some target law of the stochastic process
        obs = observs,
        t0 = 0.0, # starting time
        x0_prior = KnownStartingPt([1.0, 2.0]), # prior over the starting position
    )
)
```

## Define interdependence structure for parameters
-----------------------
If your data consist of recordings of multiple trajectories, sampled under laws that share some subsets of parameters or observation schemes sharing some parameters, then you may wish to add all of them to `AllObservations` above and then specify the interdependence structure of parameters. To this end you may use `add_dependency!` function.


For instance, to specify that the first and second recording share dependence on two common parameters (one of which under the law of recording 1 is encoded as `α1` and under the law of recording 2 is encoded as `α2` and another one, which under both recording is encoded as `:β`) we may write
```julia
add_dependency!(
    all_obs,
    Dict(
        :α_shared => [(1, :α1), (2, :α1) #= format: (idx-of-recording, param-name) =#],
        :β_shared => [(1, :β), (2, :β)],
    )
)
```
Once you're done setting up an instance of `AllObservations` call `initialize` to complete initialization.
```julia
initialised_all_obs, old_to_new_idx = initialize(all_obs)
```
The object `initialised_all_obs` will now contain all necessary information about how the data were collected, everything that is known about the underlying process that generated it, as well as the data themselves.
