# [Defining observation schemes and loading data](@id obs_scheme)
**********************
Decorating each and single one of the observations as in the previous section might become quite tiresome. However, most often we collect multiple data points according to a single (or only a few different) observation scheme(s), in which case explicitly decorating each observation separately does not really seem to be necessary. To this end we provide a struct `ObsScheme` together with a function `load_data` for a convenient way of decorating multiple observations at once.
```@docs
ObservationSchemes.ObsScheme
ObservationSchemes.load_data
```
For instance, if all data are collected according to a single observation scheme:
```julia
t, v = 1.0, [1.0, 2.0, 3.0] # dummy values, only DataType matter
obs = LinearGsnObs(t, v; full_obs=true)
```
Then we can define it as an observation scheme and load the data as follows:
```julia
# ----- raw data ------------------------#
tt = [1.0, 2.0, 3.0, 4.0, 5.0]           #
xx = [i.+rand(3) for i in eachindex(tt)] #
# -------------------------------------- #

data = load_data(ObsScheme(obs), tt, xx)
```
If more than one type of observation schemes are used then we can pass a list of them to `ObsScheme`, and then, specify the pattern in which they should be cycled through when loading in the data:
```julia
# another observation scheme:
t, v = 1.0, SVector{2,Float64}(1.0, 2.0)
obs2 = LinearGsnObs(t, v; full_obs=true)

# -------------------------------------- other raw data ------------------------#
xx = [i%2==1 ? i.+rand(3) : i.+rand(SVector{2,Float64}) for i in eachindex(tt)] #
# ------------------------------------------------------------------------------#

# load the data:
data = load_data(ObsScheme(obs, obs2; pattern=[1,2]), tt, xx)
# ↑ simply alternate between `obs` and `obs2`
```

## Generating data directly from the simulated trajectory
----
Very often we need to simulate some data from the underlying model for testing purposes. To help ourselves a little with this process we can use
```@docs
collect(os::ObservationSchemes.ObsScheme, path, step=1, record_start_pt=false)
```
We only need to simulate the trajectory and define the observation scheme. Then, we can use `collect` to generate an appropriately decorated dataset from such raw recording.

### [Example](@id example_for_obs_scheme)
For instance we can use the package [DiffusionDefinition.jl](https://github.com/JuliaDiffusionBayes/DiffusionDefinition.jl) to simulate a trajectory from the FitzHugh–Nagumo model:
```julia
using DiffusionDefinition, StaticArrays
@load_diffusion FitzHughNagumo

P = FitzHughNagumo(0.1, -0.8, 1.5, 0.0, 0.3)
tt = 0.0:0.0001:10.0
x0 = @SVector [-0.6, -0.6]
X = rand(P, tt, x0)
```
then, define the observation scheme:
```julia
obs_sch = ObsScheme(
    LinearGsnObs(
        0.0, (@SVector [0.0]);
        L = (@SMatrix [1.0 0.0;]),
        Σ = (@SMatrix [0.01;]),
    )
)
```
and then very simply generate a dataset
```julia
data = collect(obs_sch, X, 1000, false)
```
Examining the first two and the last observation yield:
```julia
julia> summary(data[1])
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (1, 2)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [-1.0821504043466732] (observation),
||  → typeof(ν): SArray{Tuple{1},Float64,1,1},
|| made at time 0.1.
|...
|L: [1.0 0.0],
|   → typeof(L): SArray{Tuple{1,2},Float64,2,2}
|μ: [0.0],
|   → typeof(μ): SArray{Tuple{1},Float64,1,1}
|Σ: [0.01],
|   → typeof(Σ): SArray{Tuple{1,1},Float64,2,1}
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆

julia> summary(data[2])
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (1, 2)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [-0.9679347555098883] (observation),
||  → typeof(ν): SArray{Tuple{1},Float64,1,1},
|| made at time 0.2.
|...
|L: [1.0 0.0],
|   → typeof(L): SArray{Tuple{1,2},Float64,2,2}
|μ: [0.0],
|   → typeof(μ): SArray{Tuple{1},Float64,1,1}
|Σ: [0.01],
|   → typeof(Σ): SArray{Tuple{1,1},Float64,2,1}
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆

julia> summary(data[end])
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (1, 2)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [0.8136510716798605] (observation),
||  → typeof(ν): SArray{Tuple{1},Float64,1,1},
|| made at time 10.0.
|...
|L: [1.0 0.0],
|   → typeof(L): SArray{Tuple{1,2},Float64,2,2}
|μ: [0.0],
|   → typeof(μ): SArray{Tuple{1},Float64,1,1}
|Σ: [0.01],
|   → typeof(Σ): SArray{Tuple{1,1},Float64,2,1}
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```
