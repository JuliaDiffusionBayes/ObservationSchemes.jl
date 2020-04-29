# [Defining observation schemes and loading data](@id obs_scheme)
Most often we collect multiple data points from a single observation scheme. Decorating each and single one of the observations as in the previous section might become quite tiring. To this end we provide a struct `ObsScheme` together with a function `load_data` for a convenient way of decorating multiple observations at once.
```@docs
ObservationSchemes.ObsScheme
ObservationSchemes.load_data
```
For instance, if all data is collect according to a single observation scheme:
```julia
t, v = 1.0, [1.0, 2.0, 3.0] # dummy values, only DataType matter
obs = LinearGsnObs(t, v; full_obs=true)
```
Then we can define it as an observation scheme and load the data as follows:
```julia
tt = [1.0, 2.0, 3.0, 4.0, 5.0]
xx = [i.+rand(3) for i in eachindex(tt)]

data = load_data(ObsScheme(obs), tt, xx)
```
If more than one type of observation schemes are used then we can specify a list of them to `ObsScheme` and then specify the pattern in which we cycle through them when loading the data:
```julia
# another observation scheme:
t, v = 1.0, SVector{2,Float64}(1.0, 2.0)
obs2 = LinearGsnObs(t, v; full_obs=true)

# observations:
xx = [i%2==1 ? i.+rand(3) : i.+rand(SVector{2,Float64}) for i in eachindex(tt)]

# load the data:
data = load_data(ObsScheme(obs, obs2; pattern=[1,2]), tt, xx)
```
