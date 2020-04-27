# Observation schemes
All observation schemes inherit from a struct `Observation{D,T}` and have
methods `eltype`, `size` and `length` implemented for them.
## Linear Gaussian struct
The most important observation scheme (and, currently, the only one that is
implemented) is `LinearGsnObs`. It is suitable for representing observations
that can be written in the following format:
```math
\begin{equation}\label{eq:obs_scheme}
V_t := LX_t+\xi,\quad \xi\sim N(μ,Σ),
\end{equation}
```
where $L\in\RR^{d\times d'}$ and $X_t$ is a state of the underlying stochastic
process. We describe various special cases of the above scheme below.
### Exact observations of the process
A degenerate case of the above is an exact observation of $X_t$, i.e. when
```math
L = I_d,\qquad μ = 0_{d\times 1},\qquad Σ = 0_{d\times d},
```
so that $X_t=V_t$. This can be defined as:
```julia
v = [1.0, 2.0, 3.0]
obs = LinearGsnObs(v; full_obs=true)
```
by default the covariance matrix of the noise `Σ` is set to
$\Sigma:=10^{-11}I_{d}$ for numerical reasons. This can be changed by specifying
`Σ` explicitly, for instance to increase the level of "artificial noise":
```julia
using LinearAlgebra
obs = LinearGsnObs(v; Σ=(1e-5)I, full_obs=true)
```
Specifying `full_obs=true` is important, as it lets the compiler differentiate
between an actual, full observation with some artificial noise and a (possibly)
partial observation with very low level (or also artificial level) of noise.
As a result, the compiler knows when the Markov property can be applied!
### Linear transformations of the process disturbed by Gaussian noise
A standard understanding of the expression in \eqref{eq:obs_scheme}. An example
could be:
```julia
using StaticArrays
v = @SVector [1.0, 2.0, 3.0]
tt = 2.0
L = @SMatrix [1.0 0.0 2.0 0.0; 3.0 4.0 0.0 0.0; 0.0 1.0 0.0 1.0]
Σ = SDiagonal(1.0, 1.0, 1e-11)
obs = LinearGsnObs(tt, v; L = L, Σ = Σ)
```
for defining a three-dimensional observation `v` made at time $2.0$ of a
four-dimensional process $X$, where the first coordinate of the observation is
$X_t^{[1]}+2X_t^{[3]}+\xi^{[1]}$, with $\xi^{[1]}\sim N(0,1)$,
the second coordinate is
$3X_t^{[1]}+4X_t^{[2]}+\xi^{[2]}$, with $\xi^{[2]}\sim N(0,1)$,
and the third coordinate is
$X_t^{[2]}+X_t^{[4]}$, with no real noise (only an artificial one, needed for
numerical reasons). We can display the summary of the observation with:
```julia
show(obs)
```
### First-passage time observations
Support for certain first-passage time settings is provided. Currently, the
coordinate that is observed in a first-passage time setting **must be devoid
of any Wiener noise**. By default `LinearGsnObs` sets the first-passage time
info to `NoFirstPassageTimes`. However, this can be changed. For instance, to
indicate in the example above that the last coordinate of `v` actually reaches
level $3.0$ for the very first time at time $2.0$ we can specify the following:
```julia
fpt = FirstPassageTimeInfo(
    (3,),
    (3.0,),
    (true,),
    (false,),
    (),
)
obs = LinearGsnObs(tt, v; L = L, Σ = Σ, fpt = fpt)
```
The last two entries in `fpt` specify additional reset times. For instance,
instead of `(false,)` and `()` we could set `(true,)`, `(-1.0)` to indicate that
the process $X_t^{[2]}+X_t^{[4]}$ can do whatever before it falls below level
$-1.0$ (in particular it can go above level $3.0$), and that once it falls below
$-1.0$, then from then on the first time it reaches level $3.0$ happens at time
$2.0$. Note that
```julia
show(obs)
```
changes appropriately to display the new summary of the first-passage time info.
## Beyond linearity and Gaussianity
[TODO currently not implemented]
