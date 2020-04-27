# ObservationSchemes.jl
This is a utility package belonging to a suite of packages
[BridgeSDEInference.jl](https://github.com/mmider/BridgeSDEInference.jl). Its
purpose is to provide systematic treatment of observation schemes for diffusion
processes. The following types of observations are aimed at being implemented in
this package:
- [x] Full observations of the underlying process
- [x] Linear translations of the underlying process, disturbed by Gaussian noise
- [x] First-passage time observations
- [x] First-passage time observations with additional resetting
- [x] Multiple observations of a single process
- [x] Multiple observations of multiple processes, coming possibly from different laws that share subsets of parameters (mixed-effect models)
- [ ] Non-linear observations
- [ ] Non-Gaussian observations
Additionally, we provide infrastructure for defining priors over starting points
Follow an [Overview](overview/observation_schemes) section to find out about
various functionalities implemented in this package.
