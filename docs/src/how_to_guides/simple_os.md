# [How to ergonomically deal with simple observation schemes?](@id simple_observation_schemes)
***

Often times the data are collected according to a single, or maybe only two different observational regimes. For instance, we might be recording a single coordinate of a process with low precision but high frequency and additionally make low frequency but high precision observation of all coordinates. In these types of scenarios the most convenient way of preparing the data is to use `ObsScheme` struct that you can read more about [here](@ref obs_scheme).

Simply define a list of all observation regimes that you will be using:
```julia
using ObservationSchemes, StaticArrays
all_obs_types = [
    LinearGsnObs(
        0.0, (@SVector [0.0]);
        L = (@SMatrix [0.0 1.0 0.0;]), # observe only the second coordinate,
        Σ = (@SMatrix [1.0;]), # low precision
    ),
    LinearGsnObs(
        0.0, (@SVector [0.0, 0.0, 0.0]);
        L = SDiagonal(1.0, 1.0, 1.0), # observe all coordinates,
        Σ = 1e-5*SDiagonal(1.0, 1.0, 1.0), # high precision
    ),
]
```
And define a pattern in which the templates from `all_obs_types` are going to be used to record the observations
```julia
# 5 low precis obs, 1 high precis obs, 5 low precis obs, 1 high precis obs, etc...
obs_sch = ObsScheme(all_obs_types...; pattern=[1,1,1,1,1,2])
```
Then you can take your raw data and decorate it:
```julia
raw_data_tt_and_xx_pairs = ...

data = load_data(obs_sch, raw_data_tt_and_xx_pairs)
```

If you are doing some testing and don't have the raw data yet, just a full, simulated trajectory from the model, you may collect the data directly according to the scheme `obs_sch` (the data will be perturbed by the noise that you've specified) optionally recording the data in jumps (because the observations might be done once every `τ` seconds, where `τ > dt`, `dt` being the time-step used to simulate the trajectory):
```julia
path = ...

data = collect(obs_sch, path, 1000 #= record 1 in 1000 pts =#, false #= omit start pt =#)
```
