# ObservationSchemes.jl

This is a utility package belonging to a suite of packages
[DiffusionBayes.jl](https://github.com/JuliaDiffusionBayes/DiffusionBayes.jl). Its
purpose is to provide a systematic treatment of discrete-time observation schemes for stochastic processes.

The underlying idea is to provide a set of decorators that can be used to equip each data-point separately, and in doing so, describe how a given data-point has been recorded. This flexible framework can be used to define incredibly complex observation schemes in a simple way.

The following types of observations can be defined with this package:
- Full, exact observations of the underlying process
- Linear translations of the underlying process, disturbed by Gaussian noise
- First-passage time observations
- First-passage time observations with additional `resetting events`
- Non-linear observations & non-Gaussian discrete-time observations
- Parameterized versions of all observation types above

Additionally, we provide functionality to couple multiple observations to denote:
- Multiple observations of a single process
- Multiple observations of multiple processes, coming possibly from different laws that share subsets of parameters (mixed-effect models)

Finally, we provide infrastructure for defining priors over starting points. In particular we add concrete implementations of
- Degenerate priors corresponding to fixed starting points
- Gaussian priors

Depending on your experience and intended use of this package you might consider starting at different places of this documentation.

- For a quick overview of this package's main functionality see [Get started](@ref get_started)
- For a systematic introduction to all functionality introduced in this package see the [Manual](@ref manual_overview)
- For a didactic introduction to problems that can be solved using our package see the [Tutorials](@ref tutorial_single_path)
- If you have a problem that you think can be addressed with this package, then check out the [How-to guides](@ref simple_observation_schemes) to see if the answer is already there.
