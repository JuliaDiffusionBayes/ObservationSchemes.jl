# How to work with dataframes?
----
[DataFrames.jl](https://juliadata.github.io/DataFrames.jl/stable/) is a very useful package for dealing with data. We don't use it explicitly in any packages of [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes), however, it is likely that some users of [JuliaDiffusionBayes](https://github.com/JuliaDiffusionBayes) packages will want to store their observations in a DataFrame.

If your raw data is stored in two columns:
```julia
raw_data = DataFrame(
    t = [...],
    x = [...],
)
```
you can simply pass those two columns to `load_data`:
```julia
obs_scheme = ...
data = load_data(obs_scheme, raw_data.t, raw_data.x)
```
You may then construct a dataframe with your decorated data
```julia
df = DataFrame(data=data)
```
