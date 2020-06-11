# How to read data directly from a `.csv` file?
***
If your data are saved in a `.csv` file such that each row `i` contains
`time-of-obs_i, obs_i-coord_1, obs_i-coord_2, obs_i-coord_3, ...`, then you can load the data in using function `load_data` and passing a path to your file, as in:
```julia
obs_scheme = ...
data = load_data(obs_scheme, "path/to/your/file/filename.csv")
```
