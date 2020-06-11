# ObservationSchemes.jl

[![Stable](https://img.shields.io/badge/docs-stable-blue.svg)](https://JuliaDiffusionBayes.github.io/ObservationSchemes.jl/stable)
[![Dev](https://img.shields.io/badge/docs-dev-blue.svg)](https://JuliaDiffusionBayes.github.io/ObservationSchemes.jl/dev)
[![Build Status](https://travis-ci.com/JuliaDiffusionBayes/ObservationSchemes.jl.svg?branch=master)](https://travis-ci.com/JuliaDiffusionBayes/ObservationSchemes.jl)

A utility package from the [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes) suite, used for defining observation schemes for stochastic processes. It is aimed primarily at encoding discrete-time observations of diffusions.

The main type of observation scheme is

![equation](https://latex.codecogs.com/gif.latex?V_T%5Csim%20%5Cmathcal%7BN%7D%28LX_T%2C%20%5CSigma%29)

i.e. linearly transformed process, disturbed by Gaussian noise, however, the package can handle more general types of observations, such as

![equation](https://latex.codecogs.com/gif.latex?V%5Csim%20g%28X%29&plus;%5Cxi)

with general function `g` and random variable `ξ`. Additionally, first-passage time observations are supported. We also provide infrastructure for defining priors over starting points. For more details [see the documentation](https://JuliaDiffusionBayes.github.io/ObservationSchemes.jl/dev).
