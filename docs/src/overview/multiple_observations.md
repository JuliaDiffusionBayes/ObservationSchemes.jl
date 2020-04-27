# Multiple observations
Multiple discrete-time observations of a single trajectory are referred to in
this package as a single **recording**. Below we describe how to handle
observations of
- a single recording
- multiple recordings from the same law
- multiple recordings from multiple laws
## Defining a single recording
To fully describe a single recording we need four elements:
- A diffusion law that the underlying process is following
- A starting time
- A prior over the starting point
- Discrete-time observations of the process
Consequently, this package adopts the convention of defining a single recording
with a `NamedTuple`:
```julia
recording = (
    P = ...,
    obs = ...,
    t0 = ...,
    x0_prior = ...,
)
```
The law `P` needs to be defined by the user and a package
[DiffusionDefinition.jl](https://github.com/mmider/DiffusionDefinition.jl)
can be used to this end. **There must exist an implementation of a function `param_name(::typeof(P))` if one wants to use functions and structs presented
below**. `obs` is assumed to be a vector of observations, with each element
being of the type inheriting from `Observation{D,T}`. `x0_prior` is assumed
to inherit from `StartingPtPrior{T}`.

## Defining multiple recordings
### Recordings under a single, shared law
A struct `AllObservations` allows for a systematic definition of multiple
recordings and, in addition, provides some handy functionality. For instance,
we can define multiple recordings as follows:
```julia
struct LawA α; β; end
DiffObservScheme.param_names(P::LawA) = [:α, :β]

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
Observations can be accessed via `all_obs.recordings`. By default the laws from
different recordings are assumed to be independent, but we can tell
`AllObservations` object that they are the same by indicating that the laws
share some subsets (possibly all) parameters. This can be done by passing an
appropriate dictionary to function `add_dependency`:
```julia
add_dependency!(
    all_obs,
    Dict(
        :α_shared => [(rec=1, p_name=:α), (rec=2, p_name=:α)],
        :β_shared => [(rec=1, p_name=:β), (rec=2, p_name=:β)],
    )
)
```
The first (respectively second) entry in the dictionary tells `all_obs` that
there is a parameter, which from now on will be labeled `:α_shared` (resp.
`:β_shared`), that is present in the law of recording `1` and the law of
recording `2` and in both of these cases if one calls `param_name(P)` then the
referred to parameter should have a name `:α` (resp. `:β`). We can also tell
the same thing to `AllObservations` object differently:
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
this parameter takes when a call to `param_name(P)` is made. We can also specify
both and then the error will be thrown if two access paths are not pointing to
the same parameter. The names of the `NamedTuple`s:
`(rec=..., p_idx=)`, `(rec=..., p_name=...)` and
`(rec=..., p_idx=..., p_name=...)` above don't matter (in fact they are
later downgraded to regular `tuples`), only the order of their entries. Now, we
can additionally call:
```julia
initialised_all_obs = initialise!(all_obs)
```
to perform two useful operations. First, all parameters that are not shared
between various laws will be marked (here, there is no such parameter, so this
step does not do anything, see example below which illustrates this idea),
second, the recordings are split at the times at which full observations are
made, as full observations allows for employment of Markov property and
treatment of the problem in parallel. As a result, `initialised_all_obs` now
has `5` recordings, all coming from the same law `LawA`.

### Recordings under multiple laws
It should be clear that the formalism above allows for definition of recordings
coming from multiple diffusion laws. For instance, we can have
```julia
struct LawB γ; β; end
DiffObservScheme.param_names(P::LawB) = [:γ, :β]

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
The dictionary specifying interdependence between diffusion laws can now be
defined as follows:
```julia
add_dependency!(
    all_obs,
    Dict(
        :α_shared => [(rec=1, p_name=:α), (rec=2, p_name=:α)],
        :β_shared => [(rec=1, p_name=:β), (rec=2, p_name=:β), (rec=3, p_name=:β)],
    )
)
```
where, notice presence of additional `(rec=3, p_name=:β)`. Now, calling
```julia
initialised_all_obs = initialise!(all_obs)
```
not only splits the recordings at the time of full observations (resulting in
`6` independent recordings), but also introduces a new named parameter
`REC3_γ` that only the last recording depends on. This comes from the fact that
in the original `all_obs` the third recording came from law `LawB`, which
depended on a parameter `γ` that was not shared with any other recording and
hence did not appear in the interdependency dictionary. Every such "lonely"
parameter is introduced by a function `initialise!` and is given a name by
prepending its original name with `REC($i)_`, with `($i)` denoting the original
index of a recording that the parameter came from.
