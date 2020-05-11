# [Installation](@id get_started)
---------------------------------
The package is not registered yet. To install it write:
```julia
] add https://github.com/JuliaDiffusionBayes/ObservationSchemes.jl
```
# A single observation
---------------------
To define a single observation collected according to
```math
V_t = LX_t+\xi,\quad \xi\sim N(\mu,\Sigma),
```
call
```julia
using LinearAlgebra
ν = [1.0, 2.0, 3.0]
t = 2.0
L = [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0]
Σ = Diagonal([1.0, 1.0, 1e-11])
obs = LinearGsnObs(t, ν; L = L, Σ = Σ) # μ is defaulted to 0
```
For a general observation scheme:
```math
V_t = g(X_t) + \xi,\quad \xi\sim \Xi
```
you may use `GeneralObs` instead of `LinearGsnObs`, but you must provide the function $$g$$, the law $$\Xi$$ (and an approximation via `LinearGsnObs` if you wish to use it with other packages in [DiffusionBayes](https://github.com/JuliaDiffusionBayes/DiffusionBayes.jl)).

# Multiple observations
-----------------------
To define multiple observations at once define a list of observation formats in which the data was collected:
```julia
# type 1
t, v = 1.0, [1.0, 2.0, 3.0] # dummy values, only DataType matter
obs = LinearGsnObs(t, v; full_obs=true)

# type 2, i.e. another observation scheme:
t, v = 1.0, SVector{2,Float64}(1.0, 2.0)
obs2 = LinearGsnObs(t, v; full_obs=true)

# data defined externally:
tt, xx = ...

# decorate the data
observs = load_data(ObsScheme(obs, obs2; pattern=[1,2]), tt, xx)
```
These can then be put in a container that collects observations of multiple trajectories:
```julia
all_obs = AllObservations()
add_recording!(
    all_obs,
    (
        P = ...,
        obs = observs,
        t0 = ...,
        x0_prior = ...,
    )
)
```

# Define interdependence structure for parameters
-----------------------
If your data consist of recordings of multiple trajectories, sampled under laws that share some subsets of parameters or observation schemes sharing some parameters, then you may wish to specify the interdependence structure. To this end you may use `add_dependency!` function:
```julia
add_dependency!(
    all_obs,
    Dict(
    :α_shared => [(rec=1, law_else_obs=true, p_name=:α), (rec=2, law_else_obs=true, p_name=:α)],
    :β_shared => [(rec=1, law_else_obs=true, p_name=:β), (rec=2, law_else_obs=true, p_name=:β)],
    )
)
```
Once you're done setting up an instance of `AllObservations` call `initialize` to build some useful internal structures for fast iteration over interdependence structure.
```julia
initialised_all_obs, old_to_new_idx = initialize(all_obs)
```
