<h1 align="center">
  <br>
  <a href="https://juliadiffusionbayes.github.io/ObservationSchemes.jl/dev/"><img src="https://raw.githubusercontent.com/JuliaDiffusionBayes/ObservationSchemes.jl/master/docs/src/assets/logo.png" alt="ObservationSchemes.jl" width="200"></a>
  <br>
  ObservationSchemes.jl
  <br>
</h1>

> A utility package from the [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes) suite, used for defining observation schemes for stochastic processes. It is aimed primarily at encoding discrete-time observations of diffusions.

<p align="center">
  <a href="https://JuliaDiffusionBayes.github.io/ObservationSchemes.jl/stable">
    <img src="https://img.shields.io/badge/docs-stable-blue.svg"
         alt="Stable">
  </a>
  <a href="https://JuliaDiffusionBayes.github.io/ObservationSchemes.jl/dev"><img src="https://img.shields.io/badge/docs-dev-blue.svg" alt="Dev"></a>
  <a href="https://travis-ci.com/JuliaDiffusionBayes/ObservationSchemes.jl">
      <img src="https://travis-ci.com/JuliaDiffusionBayes/ObservationSchemes.jl.svg?branch=master" alt="Build Status">
  </a>
</p>

<p align="center">
  <a href="#key-features">Key Features</a> •
  <a href="#installation">Installation</a> •
  <a href="#how-to-use">How To Use</a> •
  <a href="#related">Related</a> •
  <a href="#license">License</a>
</p>

## Key Features

- Decorate each observation separately with the information about how it was collected
- Support for the following observations:
  - Exact observations of all or a subset of all coordinates of the underlying process
  - Linear translations of the underlying process, disturbed by Gaussian noise: ![equation](https://latex.codecogs.com/gif.latex?V_T%5Csim%20%5Cmathcal%7BN%7D%28LX_T%2C%20%5CSigma%29)
  - First-passage time observations
  - First-passage time observations with additional "resetting events"
  - Non-linearly (or linearly) transformed observations with Gaussian or non-Gaussian noise, i.e.: ![equation](https://latex.codecogs.com/gif.latex?V%5Csim%20g%28X%29&plus;%5Cxi) with general function `g` and random variable `ξ`
  - Parameterized versions of all observation types above
- Support for ergonomic definitions of
  - Multiple observations of a single process
  - Multiple observations of multiple processes, coming possibly from different laws that share subsets of parameters (mixed-effect models)
- Support for defining priors over starting points:
  - Degenerate priors corresponding to fixed starting points
  - Gaussian priors

## Installation

```julia
] add ObservationSchemes
```

## How To Use

See [the documentation](https://juliadiffusionbayes.github.io/ObservationSchemes.jl/dev/).

## Related

ObservationSchemes.jl belongs to a suite of packages in [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes), whose aim is to facilitate Bayesian inference for diffusion processes. Some other packages in this suite are as follows:
- [DiffusionDefinition.jl](https://github.com/JuliaDiffusionBayes/DiffusionDefinition.jl): define diffusion processes and sample from their laws
- [GuidedProposals.jl](https://github.com/JuliaDiffusionBayes/GuidedProposals.jl): defining and sampling conditioned diffusion processes
- [ExtensibleMCMC.jl](https://github.com/JuliaDiffusionBayes/ExtensibleMCMC.jl): a modular implementation of the Markov chain Monte Carlo (MCMC) algorithms
- [DiffusionMCMC.jl](https://github.com/JuliaDiffusionBayes/DiffusionMCMC.jl): Markov chain Monte Carlo (MCMC) algorithms for doing inference for diffusion processes

## License

MIT
