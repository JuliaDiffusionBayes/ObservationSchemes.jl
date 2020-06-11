# How to save decorated data to a file?
***

A convenient way to save decorate data to a file is to use the package [JuliaDB.jl](https://juliadata.github.io/JuliaDB.jl/stable/).

Once you've decorated your data, simply create a `JuliaDB` table:
```julia
dec_data = ...

using JuliaDB

t = table(1:length(dec_data), dec_data, pkey=1)
```
and save it to the disk
```julia
save(t, "path/to/destination/filename.db")
```

Your file will contain decorated data i.e. complete information about the underlying process and how the data was collected together with the data themselves will be in that file–no need for having to specify anything else externally.

You can then load the data back in with
```julia
t = load("path/to/destination/filename.db")
```
