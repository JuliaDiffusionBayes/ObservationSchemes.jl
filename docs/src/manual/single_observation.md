# [Observation schemes](@id manual_start)
************************************************
All observation schemes inherit from
```@docs
ObservationSchemes.Observation
```
which has methods
```@docs
ObservationSchemes.eltype
ObservationSchemes.size
ObservationSchemes.length
```
automatically implemented for it. The idea is to decorate each recorded data-point with such structs, and in doing so, encode the way in which it was collected.

We implemented two concrete structs that may be used for defining a single observation:
- `LinearGsnObs`: to encode observations of the linear transformations of the underlying process disturbed by Gaussian noise
- `GeneralObs`: to encode observations of non-linear transformations of the underlying process disturbed by noise.

Both admit a possibility of parameterization.

## Linear Gaussian struct
-----------------------------------
The most important observation scheme is `LinearGsnObs`.  It is suitable for representing observations that can be written in the following format:
```math
\begin{equation}\label{eq:obs_scheme}
V_t := LX_t+\xi,\quad \xi\sim N(μ,Σ),
\end{equation}
```
where $L\in\RR^{d\times d'}$ and $X_t$ is a state of the underlying stochastic
process.

```@docs
ObservationSchemes.LinearGsnObs
```

Below, we list some special cases of the scheme above.

### Exact observations of the process
A degenerate case of the setting above is an exact observation of $X_t$, i.e. when
```math
L = I_d,\qquad μ = 0_{d\times 1},\qquad Σ = 0_{d\times d},
```
so that $X_t=V_t$. This can be defined as:
```julia
t, v = 1.0, [1.0, 2.0, 3.0]
obs = LinearGsnObs(t, v; full_obs=true)
```
!!! warning
    For numerical reasons the covariance matrix of the noise `Σ` should not be a zero matrix, and instead, even in the exact observation setting should be inflated by some small `artificial noise`. By default `Σ` is set to
    $\Sigma:=10^{-11}I_{d}$ for numerical reasons. This can be changed by specifying `Σ` explicitly, for instance to increase the level of `artificial noise`:
    ```julia
    using LinearAlgebra
    obs = LinearGsnObs(t, v; Σ=(1e-5)I, full_obs=true)
    ```

Specifying `full_obs=true` is important, as it lets the compiler differentiate
between an actual, full observation with some artificial noise and a (possibly)
partial observation with very low level (or also artificial level) of noise.
**As a result, other packages from [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes) know when the Markov property can be applied.**

We can view a summary of the observation by calling `summary`:
```julia
julia> summary(obs)
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (3, 3)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| v: [1.0, 2.0, 3.0] (observation),
||  → typeof(v): Array{Float64,1},
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
```
Notice that various defaults and type-inferences have kicked in. It was recognized that the observation does not depend on any parameters, that first-passage time setting does not apply and that the observation was not of a static type and hence regular `Arrays` are used to define `L`, `μ` and `Σ`.


### [Linear transformations of the process disturbed by Gaussian noise](@id standard_example_lingsnobs)
This is a standard understanding of the expression in \eqref{eq:obs_scheme}. An example
could be:
```julia
using StaticArrays
v = @SVector [1.0, 2.0, 3.0]
t = 2.0
L = @SMatrix [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0]
Σ = SDiagonal(1.0, 1.0, 1e-11)
obs = LinearGsnObs(t, v; L = L, Σ = Σ)
```
for defining a three-dimensional observation `v` made at time $2.0$ of a
four-dimensional process $X$, where the first coordinate of the observation is
$X_t^{[1]}+2X_t^{[3]}+ξ^{[1]}$, with $ξ^{[1]} ∼ N(0,1)$,
the second coordinate is
$3X_t^{[1]}+4X_t^{[2]}+ξ^{[2]}$, with $ξ^{[2]} ∼ N(0,1)$,
and the third coordinate is
$X_t^{[2]}+X_t^{[4]}$, with no real noise (only artificial one, needed for
numerical reasons). We can display the summary of the observation with:
```julia
julia> summary(obs)
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (3, 4)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| v: [1.0, 2.0, 3.0] (observation),
||  → typeof(v): SArray{Tuple{3},Float64,1,3},
|| made at time 2.0.
|...
|L: [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0],
|   → typeof(L): SArray{Tuple{3,4},Float64,2,12}
|μ: [0.0, 0.0, 0.0],
|   → typeof(μ): SArray{Tuple{3},Float64,1,3}
|Σ: [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0e-11],
|   → typeof(Σ): Diagonal{Float64,SArray{Tuple{3},Float64,1,3}}
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```
Note that the internal containers are now set to be `SVector`s (even `μ`, which wasn't passed to a constructor but its type was inferred and its value set to zero). Additionally, Julia understands that this is not a full observation and hence Markov property cannot be applied.

### [First-passage time observations](@id first_passage_time)
Support for certain first-passage time settings is provided. By default `LinearGsnObs` sets the information about the first-passage times to
```@docs
ObservationSchemes.NoFirstPassageTimes
```
However, this can be changed by passing appropriately initialized
```@docs
ObservationSchemes.FirstPassageTimeInfo
```
For instance, to indicate in the example above that the last coordinate of `v` actually reaches level $3.0$ for the very first time at time $1.0$ we can specify the following:
```julia
t, v = 1.0, [1.0, 2.0, 3.0]
fpt = FirstPassageTimeInfo(
    (3,),
    (3.0,),
    (true,),
    (false,),
    (),
)
obs = LinearGsnObs(t, v; L = L, Σ = Σ, fpt = fpt)
```
The last two entries in `fpt` specify additional reset times. For instance,
instead of `(false,)` and `()` we could set `(true,)`, `(-1.0)` to indicate that
the process $X_t^{[2]}+X_t^{[4]}$ can do whatever before it falls below level
$-1.0$ (in particular it can go above level $3.0$), and that once it falls below
$-1.0$, then from then on the first time it reaches level $3.0$ happens at time
$1.0$. Note that
```julia
julia> summary(obs)
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (3, 4)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| v: [1.0, 2.0, 3.0] (observation),
||  → typeof(v): Array{Float64,1},
|| made at time 1.0.
|...
|L: [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0],
|   → typeof(L): SArray{Tuple{3,4},Float64,2,12}
|μ: [0.0, 0.0, 0.0],
|   → typeof(μ): Array{Float64,1}
|Σ: [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0e-11],
|   → typeof(Σ): Diagonal{Float64,SArray{Tuple{3},Float64,1,3}}
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|First passage times of the observation `v`:
|----------------------------------------------------------------------------
||  coordinate  |     level    |  up-crossing |  extra reset |  reset level |
|----------------------------------------------------------------------------
||       3      |      3.0     |  up-crossing |       ✘      |       ✘      |
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```
changes appropriately to display the new summary of the first-passage time information.

!!! note
    This package is agnostic with respect to the algorithms that are later used on the decorated observations. Consequently it doesn't make any checks for whether the observations make sense. For instance in the package [GuidedProposals.jl](https://github.com/JuliaDiffusionBayes/GuidedProposals.jl) that deals with simulating conditioned diffusions, a support for first-passage time observations is currently extended only to diffusions  where the dynamics of the coordinate whose first-passage time is observed **is devoid of any Wiener noise**. The onus of checking whether this or other constraints are satisfied are on the user.

!!! tip "Why do we refer to `LinearGsnObs` as most important?"
    In practice, all other observation schemes are handled by other packages in [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes) by approximating them with a suitable `LinearGsnObs` and then correcting the resulting approximation error with the Metropolis-Hastings algorithm. Consequently, `LinearGsnObs` will be a building block of any other observation scheme.

## Parameterizing `LinearGsnObs`
---------------------------------
The observations can be parameterized by passing a vector of parameters `θ`. Additionally, a `Tag` needs to be attached that is used to differentiate at compile time between the non-parameterized observations and parameterized observations as well as among different parameterizations themselves.

For instance, to indicate in the [second example](@ref standard_example_lingsnobs) that two entries in the `L` matrix are parameterized we can write:
```julia
v = @SVector [1.0, 2.0, 3.0]
t = 2.0
L = @SMatrix [1.0 0.0 -99.9 0.0; 3.0 4.0 0.0 0.0; 0.0 -99.9 0.0 1.0]
Σ = SDiagonal(1.0, 1.0, 1e-11)
obs = LinearGsnObs(t, v; L = L, Σ = Σ, θ=[2.0, 1.0], Tag=1)
```
We are not done yet, in this case matrix `L` that we passed above is incomplete as we intend to create an actual matrix `L` by combining the matrix and the parameters we've passed. To this end, we must overwrite the behaviour of the function `L(⋅)`:
```julia
const OBS = ObservationSchemes
function OBS.L(o::LinearGsnObs{1})
    _L = MMatrix{3,4,Float64}(o.L)
    _L[1,3] = o.θ[1]
    _L[3,2] = o.θ[2]
    SMatrix{3,4,Float64}(_L)
end
```
Notice that we dispatch on the observation's tag `1`. Furthermore, when calling `summarize` matrix `L` is displayed correctly.
```julia
julia> summary(obs)
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (3, 4)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [1.0, 2.0, 3.0] (observation),
||  → typeof(ν): SArray{Tuple{3},Float64,1,3},
|| made at time 2.0.
|...
|L: [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0],
|   → typeof(L): SArray{Tuple{3,4},Float64,2,12}
|μ: [0.0, 0.0, 0.0],
|   → typeof(μ): SArray{Tuple{3},Float64,1,3}
|Σ: [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0e-11],
|   → typeof(Σ): Diagonal{Float64,SArray{Tuple{3},Float64,1,3}}
|...
|This is NOT an exact observation.
|...
|It depends on additional parameters, which are set to: (2.0, 1.0).
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```
However, now we can change parameters to new values and the matrix `L` will be updated:
```julia
OBS.update_params!(obs, [7.0, 8.0])
julia> summary(obs)
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = Lx+ξ`, where `L` is a (3, 4)-matrix, `x` is a state of the stochastic process and `ξ`∼N(μ,Σ).
|...
|| ν: [1.0, 2.0, 3.0] (observation),
||  → typeof(ν): SArray{Tuple{3},Float64,1,3},
|| made at time 2.0.
|...
|L: [1.0 0.0 7.0 0.0; 3.0 4.0 0.0 0.0; 0.0 8.0 0.0 1.0],
|   → typeof(L): SArray{Tuple{3,4},Float64,2,12}
|μ: [0.0, 0.0, 0.0],
|   → typeof(μ): SArray{Tuple{3},Float64,1,3}
|Σ: [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0e-11],
|   → typeof(Σ): Diagonal{Float64,SArray{Tuple{3},Float64,1,3}}
|...
|This is NOT an exact observation.
|...
|It depends on additional parameters, which are set to: (7.0, 8.0).
|...
|No first passage times recorded.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```

!!! note
    We used number `-99.9` just to remind ourselves that entries with this number need to be overwritten by parameters. There are however no rules or enforcements as to how the user deals with such entries.

Notice that trying to access `L` via `obs.L` will give you an incorrect result. To avoid such mistakes, always query `L`, `μ`,`Σ` and `obs` via accessors:
```@docs
ObservationSchemes.L
ObservationSchemes.μ
ObservationSchemes.Σ
ObservationSchemes.ν
ObservationSchemes.obs
```

## Non-linear, non-Gaussian observations
----------------------------------------
In principle, any observation types are supported, but this comes at a cost of having to provide some information explicitly. The main struct for specifing general observation schemes is
```@docs
ObservationSchemes.GeneralObs
```

For this struct the required parameters are the time at which the observation was recorded and the observation itself, as well as the approximation via `LinearGsnObs`. For instance, to specify the following observational scheme:
```math
V_t = g(X_t)+ξ
```
where $ξ$ is distributed according to a bivariate $T$-distribution with $4$ degrees of freedom, some specified mean $μ$ and covariance $Σ$, $g$ is given by the following non-linear function:
```math
g(x):=
\left(
    \begin{matrix}
        (x^{[1]})^2\\
        (x^{[2]})^2
    \end{matrix}
\right)
```
we may write:
```julia
using Distributions
# recording
t, v = 1.5, [1.0, 2.0]

# for the observation scheme
μ, Σ = [-1.0, 2.0], [1.0 0.0; 0.0 1.0]
dist = MvTDist(4, μ, Σ)
g(x) = view(x, 1:2).^2

# for some poor, ad-hoc Gaussian approximation
L = [2.0 0.0 0.0; 0.0 2.0 0.0]

# define observation
obs = GeneralObs(t, v, LinearGsnObs(t, v; L=L, Σ=Σ, μ=μ); dist=dist, g=g)
```
We can now view the summary:
```julia
julia> summary(obs)
⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤⏤
|Observation `v = g(x)+ξ`, where `g` is an operator defined by a function typeof(g), and `ξ` is a random variable given byDistributions.GenericMvTDist{Float64,PDMats.PDMat{Float64,Array{Float64,2}},Array{Float64,1}}.
|...
|| ν: [1.0, 2.0, 3.0] (observation),
||  → typeof(ν): SArray{Tuple{3},Float64,1,3},
|| made at time 2.0.
|...
|This is NOT an exact observation.
|...
|It does not depend on any additional parameters.
|...
|No first passage times recorded.
|...
|To inspect the linearized approximation to this observation scheme please type in:
|   summary(<name-of-the-variable>.lin_obs)
|and hit ENTER.
⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆ ⋆
```
!!! tip
    The `GeneralObs` can be decorated with first-passage time information and parameters in the same way as `LinearGsnObs` can. However, by design, you cannot set `full_obs` to `true` for `GeneralObs`.
