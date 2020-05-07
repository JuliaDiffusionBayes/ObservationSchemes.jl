function clone end

"""
    set_parameters!(objects, all_obs::AllObservations, coords, θ°)

Set new parameters in `objects`. New parameters are listed in a vector `θ°`. The
`coords` lists the subset of coordinates from the total vector `𝛩` that `θ°` is
supposed to replace. `all_obs` allows to decipher which
stores which object in objects depends on any subset of parameters. `objects` is
a list of objects in shape corresponding to `param_depend` whose parameters are
to be updated.
"""
function set_parameters!(objects, all_obs::AllObservations, coords, invcoords, θ°)
    for i in length(objects)
        for j in length(objects[i])
            objects[i][j] = clone(
                objects[i][j],
                θ°,
                invcoords,
                filter(x->(x.global_idx in coords), all_obs.law_depend[i]),
                filter(x->(x.global_idx in coords), all_obs.obs_depend[i][j])
            )
        end
    end
end

function set_parameters!(obs::Observation, ξ, η°idx, ::Val{:associate_by_position})
    for η°i in η°idx
        obs.θ[η°i.local_idx] = ξ[η°i.global_idx]
    end
    obs
end

function set_parameters!(obs::Observation, ξ, η°idx, ::Val{:associate_by_name})
    error("cannot set_parameters! for observations via parameter name association")
end
