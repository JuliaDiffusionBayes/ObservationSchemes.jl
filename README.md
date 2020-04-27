# ObservationSchemes

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaDiffusionBayes.github.io/ObservationSchemes.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaDiffusionBayes.github.io/ObservationSchemes.jl/dev)
[![Build Status](https://travis-ci.com/JuliaDiffusionBayes/ObservationSchemes.jl.svg?branch=master)](https://travis-ci.com/JuliaDiffusionBayes/ObservationSchemes.jl)

A small package with utility functions for defining observations of diffusion
processes made at a discrete grid of time-points. The following types of
observations are aimed at being implemented in this package:
- [x] Full observations of the underlying process
- [x] Linear translations of the underlying process, disturbed by Gaussian noise
- [x] First-passage time observations
- [x] First-passage time observations with additional resetting
- [x] Multiple observations of a single process
- [x] Multiple observations of multiple processes, coming possibly from different laws that share subsets of parameters (mixed-effect models)
- [ ] Non-linear observations
- [ ] Non-Gaussian observations
Additionally, we provide infrastructure for defining priors over starting points

## Examples
For instance, a single, full observation of the process made at time `1.0` can be defined as follows
```julia
using DiffObservScheme, StaticArrays
v = @SVector [1.0, 2.0, 3.0]
tt = 1.0
obs = LinearGsnObs(tt, v; full_obs=true)
```
A more complicated example with linearly translated observations, disturbed by
Gaussian noise and with one a sum of two coordinates observed in a first-passage
time setting can be defined as:
```julia
v = @SVector [1.0, 2.0, 3.0]
tt = 2.0
L = @SMatrix [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0]
Σ = SDiagonal(1.0, 1.0, 1e-11)
fpt = FirstPassageTimeInfo(
    (3,),
    (3.0,),
    (true,),
    (false,),
    (),
)
obs = LinearGsnObs(tt, v; L = L, Σ = Σ, fpt = fpt)
```
This registers an observation of `v` at time `tt`, where the observation is of
the format

![equation](https://latex.codecogs.com/gif.latex?V_T%5Csim%20%5Cmathcal%7BN%7D%28LX_T%2C%20%5CSigma%29)

and ![equation](https://latex.codecogs.com/gif.latex?%5Cinf%5C%7Bt%5Cgeq%200%20%3A%20%28LX_t%29%5E%7B%283%29%7D%3Dv%5E%7B%283%29%7D%5C%7D%3D)`tt`.

Multiple observations of (possibly) multiple processes can be handled with a struct `AllObservations`.

Finally, two standard priors over a starting point are defined:
```julia
x0 = [1.0, 2.0]
KnownStartingPt(x0)
μ, Σ = [1.0, 2.0], [1.0 0.0; 0.0 2.0]
GsnStartingPt(μ, Σ)
```
with the first one defining a (degenerate) point-mass at `x0` and the second a Gaussian
prior with mean `μ` and covariance matrix `Σ`.
