# Priors over starting points
*****************************
On top of decorating each observation with appropriate information, for stochastic processes we need to provide additional information that describes the starting position of the process (as, for instance, no observation may be made at the initial time). This is done through prior distributions.

All priors over starting points inherit from
```@docs
ObservationSchemes.StartingPtPrior
```
They all must implement the following methods
```@docs
Base.rand(G::ObservationSchemes.StartingPtPrior, [z, ρ=0.0])
ObservationSchemes.start_pt(z, G::ObservationSchemes.StartingPtPrior, P)
ObservationSchemes.start_pt(z, G::ObservationSchemes.StartingPtPrior)
ObservationSchemes.logpdf(G::ObservationSchemes.StartingPtPrior, y)
```
and should also implement
```@docs
ObservationSchemes.inv_start_pt(y, G::ObservationSchemes.StartingPtPrior, P)
```
for MCMC setting. In this package we provide implementations for the following types of starting points
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
