# [How to define custom priors over starting points?](@id how_to_custom_prior)
***
To define custom priors over starting points you should define a struct with a prior and then override the behavior of `rand` and `logpdf` for it.

For instance to define a prior that can use any distribution from [Distributions.jl](https://github.com/JuliaStats/Distributions.jl) you can write:

```julia
using Distributions

struct CustomPrior{T,S} <: StartingPtPrior{T}
    dist::S
    CustomPrior(dist::S) where S = new{typeof(rand(dist)),S}(dist)
end

# simulate a starting point
Base.rand(p::CustomPrior) = rand(p.dist)

# evaluate log density
Distributions.logpdf(p::CustomPrior, y) = logpdf(p.dist, y)
```

This is a minimal example that allows you to sample from the prior and evaluate the log-density. However, it does not allow you to employ the Crank–Nicolson scheme that turns out to be necessary for some MCMC applications. Implementing the Crank–Nicolson scheme for general distributions might not be possible and in this package we have it implemented only for the multivariate Gaussian laws.
