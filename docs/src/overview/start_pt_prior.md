# Priors over starting points
The starting points are always treated differently to observations due to the
fact that there might be no observation made at the initial time. For this
reason the package implements priors over starting points. All priors over
starting points inherit from `StartingPtPrior{T}`. They all must implement
methods `rand`, `start_pt`, `inv_start_pt` and `logpdf`.
## Known starting point
This is the simplest setting in which the starting point is assumed to be known.
It can be defined with
```julia
x0 = [1.0, 2.0]
x0_prior = KnownStartingPt(x0)
```
a call to `rand` or `start_pt` will simply return the fixed starting point and
`logpdf(x0_prior, y)` evaluates to `0` so long as `x0 == y`.
## Gaussian priors
A Gaussian prior over the starting point. Can be defined with
```julia
μ, Σ = [1.0, 2.0], [1.0 0.0; 0.0 1.0]
x0_prior = GsnStartingPt(μ, Σ)
```
to set the mean and covariance to `μ` and `Σ` respectively. The underlying idea
behind Gaussian starting point priors is that of non-centred parametrisation,
so that a possibility of local updates is granted. More precisely any sampling
is done with `z∼N(0,1)` variables, which are then transformed to `N(μ,Σ)` via
linear transformations. In particular, sampling with `rand` can be done with
local perturbations via Crank-Nicolson scheme. `inv_start_pt` returns the
non-centrally parametrised noise `z` that produces given starting point `x0` and
`start_pt` is the reverse operation.
## Other
[TODO not implemented]
