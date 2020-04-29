# Priors over starting points
The intention behind this package is to provide a complete infrastructure for defining observations for stochastic processes (though, it can find use for defining observations in other settings). Consequently, on top of decorating each observation with appropriate information, one often needs to specify some additional information regarding the starting point. This is because often no observations are made at the initial time, but we still wish to conveys our prior knowledge of where the point lies via prior distributions. For this reason the starting points are always treated differently to observations and this package provides an infrastructure for specifying priors over starting points.

All priors over starting points inherit from
```@docs
ObservationSchemes.StartingPtPrior
```
They all must implement methods `rand`, `start_pt`, and `logpdf` (and should also implement `inv_start_pt` for MCMC setting). In this package we provide implementations for the following types of starting points
- Known, fixed starting points
- Gaussian priors over starting points

## Known starting point
This is the simplest setting in which the starting point is assumed to be known.
```@docs
ObservationSchemes.KnownStartingPt
```
It can be defined with
```julia
x0 = [1.0, 2.0]
x0_prior = KnownStartingPt(x0)
```
a call to `rand` or `start_pt` will simply return the fixed starting point and
`logpdf(x0_prior, y)` evaluates to `0` so long as `x0 == y`.

## Gaussian priors
A Gaussian prior over the starting point.
```@docs
ObservationSchemes.GsnStartingPt
```
Can be defined with
```julia
μ, Σ = [1.0, 2.0], [1.0 0.0; 0.0 1.0]
x0_prior = GsnStartingPt(μ, Σ)
```
to set the mean and covariance to `μ` and `Σ` respectively. The underlying idea
behind Gaussian starting point priors is that of non-centred parametrisation,
so that a possibility of local updates is granted. More precisely any sampling
is done with `z∼N(0,Id)` variables, which are then transformed to `N(μ,Σ)` via
linear transformations. In particular, sampling with `rand` can be done with
local perturbations via Crank-Nicolson scheme.
```@docs
ObservationSchemes.rand
```

`inv_start_pt` returns the non-centrally parametrised noise `z` that produces a given starting point `x0`:
```@docs
ObservationSchemes.inv_start_pt
```

and `start_pt` is the reverse operation
```@docs
ObservationSchemes.start_pt
```
!!! tip
    To see how to define your own priors over starting points see a How-to-guide on [Defining custom priors over starting points](@ref how_to_custom_prior)
