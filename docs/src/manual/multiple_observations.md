# Multiple observations
**********************
In practice, we gather multiple observations of a single trajectory of a stochastic process. In this package, we refer to multiple discrete-time observations of a single trajectory as a single **recording**. We do not enforce any structure on a single recording and instead use a convention of using an appropriate `NamedTuple`. However, when combining **multiple recordings** into a single data object `AllObservations` it is expected that each **recording** follows the said convention.

Below we describe how to handle observations of
- a single recording
- multiple recordings from the same law
- multiple recordings from multiple laws

## Defining a single recording
-------------------------------
To fully describe a single recording we need four elements:
- The law of the underlying stochastic process
- A starting time
- A prior over the starting point
- Discrete-time observations of the process
Consequently, this package adopts the convention of defining a single recording with a `NamedTuple`:
```julia
recording = (
    P = ...,
    obs = ...,
    t0 = ...,
    x0_prior = ...,
)
```
The law `P` needs to be defined by the user.
!!! tip
    To define diffusion laws you may use [DiffusionDefinition.jl](https://github.com/mmider/DiffusionDefinition.jl). To define conditioned diffusion laws you may use [GuidedProposals.jl](https://github.com/mmider/GuidedProposals.jl).

!!! warning
    There must exist an implementation of a function `parameter_names(::typeof(P))` if one wants to use functions and structs presented below.

`obs` is assumed to be a vector of observations, with each element
being of the type inheriting from `Observation{D,T}`. `x0_prior` is assumed
to inherit from `StartingPtPrior{T}`.

## Defining multiple recordings
-------------------------------
A struct `AllObservations` allows for a systematic definition of multiple
recordings and, in addition, provides some handy functionality.
```@docs
ObservationSchemes.AllObservations
```
### Recordings under a single, shared law
We can define multiple recordings as follows:
```julia
const OBS = ObservationSchemes
struct LawA α; β; end
OBS.parameter_names(P::LawA) = [:α, :β]

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
    ),
    (
        P = LawA(10,20),
        obs = [
            LinearGsnObs(1.3, 1.0; full_obs=true),
            LinearGsnObs(2.3, 2.0; full_obs=true),
            LinearGsnObs(3.3, 3.0; full_obs=true),
        ],
        t0 = 0.3,
        x0_prior = KnownStartingPt(-2.0),
    ),
]

all_obs = AllObservations()
for recording in recordings
    add_recording!(all_obs, recording)
end
```
!!! note
    In here we defined the vector `recordings` verbatim, however we provide an `ObsScheme` struct together with `@load_data` macro to do this in an automatic and concise way for many observations at once (see [the following section](@ref obs_scheme)).

Observations can be accessed via `all_obs.recordings`. By default the laws from
different recordings are assumed to be independent, but we can tell
`AllObservations` object that they are the same by indicating that the laws
share some subsets (possibly all) parameters. This can be done by passing an
appropriate dictionary to a function `add_dependency`:
```@docs
ObservationSchemes.add_dependency!
```

```julia
add_dependency!(
    all_obs,
    Dict(
    :α_shared => [(rec=1, law_else_obs=true, p_name=:α), (rec=2, law_else_obs=true, p_name=:α)],
    :β_shared => [(rec=1, law_else_obs=true, p_name=:β), (rec=2, law_else_obs=true, p_name=:β)],
    )
)
```
The first (respectively second) entry in the dictionary tells `all_obs` that
there is a parameter, which from now on will be labeled `:α_shared` (resp.
`:β_shared`), that is present in the law of recording `1` and the law of
recording `2` and in both of these cases if one calls `parameter_names(P)` then the
referred to parameter should have a name `:α` (resp. `:β`). The flag `law_else_obs` indicates that the referred to parameter is placed in the definition of a law, and not in the definition of a parameterized observation. We can also tell the same thing to `AllObservations` object differently:
```julia
add_dependency!(
    all_obs,
    Dict(
        :α_shared => [(rec=1, p_idx=1), (rec=2, p_name=:α)],
        :β_shared => [(rec=1, p_idx=2, p_name=:β), (rec=2, p_idx=2)],
    )
)
```
where instead of specifying the name via `p_name` we specify the index which
this parameter takes when a call to `parameter_names(P)` is made. We can also specify
both and then the error will be thrown if two access paths are not pointing to
the same parameter.
!!! note
    The names of the `NamedTuple`s
    * `(rec=..., p_idx=)`
    * `(rec=..., p_name=...)` and
    * `(rec=..., p_idx=..., p_name=...)`
    above don't matter (in fact they are later downgraded to regular `tuples`), only the order of their entries.

Now, we can additionally call
```@docs
ObservationSchemes.initialize
```
as in:
```julia
initialised_all_obs, old_to_new_idx = initialize(all_obs)
```
to perform three useful operations.
1. First, all parameters that are not shared between various laws will be marked (here, there is no such parameter, so this step does not do anything, see example below which illustrates this idea),
2. Second, the recordings are split at the times at which full observations are made, as full observations allows for employment of Markov property and treatment of the problem in parallel. As a result, `initialised_all_obs` now has `5` recordings, all coming from the same law `LawA`.
3. Third, an additional dependence structure is introduced that allows for efficient retrieval of information about parameter dependence when iterating through laws and observations.

!!! tip
    The `old_to_new_idx` might be helpful for keeping track of the original indices of recordings.

### Recordings under multiple laws
It should be clear that the formalism above allows for definition of recordings
coming from multiple diffusion laws. For instance, we can have
```julia
struct LawB γ; β; end
OBS.parameter_names(P::LawB) = [:γ, :β]

extra_recording = (
    P = LawB(30,40),
    obs = [
        LinearGsnObs(1.5, 1.0; Σ=1.0),
        LinearGsnObs(2.5, 2.0; Σ=1.0),
    ],
    t0 = 0.5,
    x0_prior = KnownStartingPt(10.0),
)
push!(recordings, extra_recording)

all_obs = AllObservations()
for recording in recordings
    add_recording!(all_obs, recording)
end
```
The dictionary specifying interdependence between the laws of stochastic processes can now be defined as follows:
```julia
add_dependency!(
    all_obs,
    Dict(
        :α_shared => [(rec=1, law_else_obs=true, p_name=:α), (rec=2, law_else_obs=true, p_name=:α)],
        :β_shared => [(rec=1, law_else_obs=true, p_name=:β), (rec=2, law_else_obs=true, p_name=:β), (rec=3, law_else_obs=true, p_name=:β)],
    )
)
```
where, notice presence of additional `(rec=3, law_else_obs=true, p_name=:β)`. This time, calling
```julia
initialised_all_obs, _ = initialize(all_obs)
```
not only splits the recordings at the time of full observations (resulting in
`6` independent recordings), but also introduces a new named parameter
`REC3_γ` that only the last recording depends on. This comes from the fact that
in the original `all_obs` the third recording came from law `LawB`, which
depends on a parameter `γ` that was not shared with any other recording and
hence did not appear in the inter-dependency dictionary. Every such "lonely"
parameter is introduced by a function `initialise!` and is given a name by
pre-pending its original name with `REC($i)_`, with `($i)` denoting the original
index of a recording that the parameter came from.

!!! warning
    Introducing parameterized observations and indicating their positions is not yet fully supported
