# How to leverage `AllObservations` to efficiently update parameters?
***
The main strength of `AllObservations` struct is that it holds information about which parameters appear in which diffusion law or in which observation. In that way, you can work on a single, **global** vector of parameters and if at any point any of those parameters change, then you may leverage `AllObservations` to quickly identify all laws and observations that depended on a changed parameter and then update them.

For instance
```julia
using ObservationSchemes
const OBS = ObservationSchemes
mutable struct LawA α; β; end
OBS.var_parameter_names(P::LawA) = (:α, :β)
mutable struct LawB γ; β; end
OBS.var_parameter_names(P::LawB) = (:γ, :β)

recordings = [
    (
        P = LawA(10,20),
        obs = [
            LinearGsnObs(1.0, 1.0; Σ=1.0),
            LinearGsnObs(2.0, 2.0; full_obs=true),
            LinearGsnObs(3.0, 3.0; Σ=2.0),
        ],
        t0 = 0.0,
        x0_prior = KnownStartingPt(2.0),
    ), # recording n°1
    (
        P = LawA(10,20),
        obs = [
            LinearGsnObs(1.3, 1.0; full_obs=true),
            LinearGsnObs(2.3, 2.0; full_obs=true),
            LinearGsnObs(3.3, 3.0; full_obs=true),
        ],
        t0 = 0.3,
        x0_prior = KnownStartingPt(-2.0),
    ), # recording n°2
    (
        P = LawB(30,40),
        obs = [
            LinearGsnObs(1.5, 1.0; Σ=1.0),
            LinearGsnObs(2.5, 2.0; Σ=1.0),
        ],
        t0 = 0.5,
        x0_prior = KnownStartingPt(10.0),
    ), # recording n°3
]

all_obs = AllObservations()
add_recordings!(all_obs, recordings)

add_dependency!(
    all_obs,
    Dict(
        :α_shared => [(1, :α), (2, :α)],
        :β_shared => [(1, :β), (2, :β), (3,:β)],
    )
)

ao, _ = initialize(all_obs)
```

```julia
julia> print_parameters(ao)

There are 6 independent recordings.
There are also 3 variable parameters.
* * *
You may define the var-parameters using the following template:
# start of template
using OrderedCollections

θ_init = OrderedDict(
    :β_shared => ... , # param 1
    :α_shared => ... , # param 2
    :REC3_γ => ... , # param 3
)
# end of template
and in an MCMC setting you may let your parameter update step
refer to a subset of indices you wish to update using the order
given above.
* * *
```

We have

```julia
julia> for rec in ao.recordings
           println(rec.P)
       end
LawA(10, 20)
LawA(10, 20)
LawA(10, 20)
LawA(10, 20)
LawA(10, 20)
LawB(30, 40)
```

Suppose that `:α_shared` (corresponding to all instances of `:α` in probability laws) changed to `100.0`. To make this change write:

```julia
global_pname = :α_shared
new_val = 100

(
    p->setfield!(
        ao.recordings[p[1]].P,
        p[2],
        new_val
    )
).(
    ao.param_depend[global_pname]
)
```

Inspecting the laws now:

```julia
julia> for rec in ao.recordings
           println(rec.P)
       end
LawA(100.0, 20)
LawA(100.0, 20)
LawA(100.0, 20)
LawA(100.0, 20)
LawA(100.0, 20)
LawB(30, 40)
```

In here we've modified the local fields of the `AllObservations` containing the target laws. However, in practice, these fields are usually considered to be dummies and instead we have a different array of laws corresponding to recordings on which we want to change the parameters. For instance:

```julia
PP = [deepcopy(rec.P) for rec in ao.recordings]
```

Then, we we update parameters, we usually want to update `PP`, not `ao.recordings[i].P`s. This is of course easily done analogously to how it was done above:

```julia
(
    p->setfield!(
        PP[p[1]],
        p[2],
        new_val
    )
).(
    ao.param_depend[global_pname]
)
```
