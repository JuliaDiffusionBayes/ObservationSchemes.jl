# ObservationSchemes.jl

This is a utility package belonging to a suite of packages
[DiffusionBayes.jl](https://github.com/JuliaDiffusionBayes/DiffusionBayes.jl). Its
purpose is to provide a systematic way of encoding discrete-time observations for stochastic processes.

The underlying idea behind the package is to provide a set of decorators that may be used to equip each data-point separately, and in doing so, describe how a given data-point has been recorded. This flexible framework can be used to define complex observation schemes in a simple way.

The following types of observations can be defined with this package:
- Exact observations of all or a subset of all coordinates of the underlying process
- Linear translations of the underlying process, disturbed by Gaussian noise (or non-Gaussian noise)
- First-passage time observations
- First-passage time observations with additional [resetting events](@ref first_passage_time)
- Non-linear observations with Gaussian or non-Gaussian noise
- Parameterized versions of all observation types above

Additionally, the package provides functionality to couple multiple observations together, so as to define:
- Multiple observations of a single process
- Multiple observations of multiple processes, coming possibly from different laws that share subsets of parameters (mixed-effect models)

Finally, we provide infrastructure for defining priors over starting points. In particular we add concrete implementations of
- Degenerate priors corresponding to fixed starting points
- Gaussian priors

----------------------------------------------

Depending on your intended use of this package you might choose to start at different places:

- For a quick overview of [ObservationSchemes.jl](https://github.com/JuliaDiffusionBayes/ObservationSchemes.jl)'s main functionality see [Get started](@ref get_started)
- For a systematic introduction to all functionality introduced in this package see the [Manual](@ref manual_start)
- For a didactic introduction to problems that can be solved using [ObservationSchemes.jl](https://github.com/JuliaDiffusionBayes/ObservationSchemes.jl) see the [Tutorials](@ref tutorial_single_path)
- If you have a problem that you think can be addressed with this package, then check out the [How-to guides](@ref simple_observation_schemes) to see if the answer is already there.
