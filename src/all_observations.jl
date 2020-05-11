#=
    Defines a container for multiple recordings of discrete-time observations
    of diffusion processes. The main object is `AllObservations`
=#
const _PARAM_DEPEND_ENTRY_TYPE = (
    Vector{
        NamedTuple{
            (:rec_idx,:law_else_obs,:obs_idx,:param_idx,:param_name),
            Tuple{Int64,Bool,Int64,Int64,Symbol}
        }
    }
)

const _LAW_OBS_DEPEND_ENTRY_TYPE = (
    NamedTuple{
        (:global_idx,:pname,:local_idx),
        Tuple{Int64,Symbol,Int64}
    }
)

const _PARAM_DEPEND_TYPE = Dict{Symbol,_PARAM_DEPEND_ENTRY_TYPE}
const _LAW_DEPEND_TYPE = Vector{Vector{_LAW_OBS_DEPEND_ENTRY_TYPE}}
const _OBS_DEPEND_TYPE = Vector{Vector{Vector{_LAW_OBS_DEPEND_ENTRY_TYPE}}}


#NOTE this function must be overwritten from `Main`.
parameter_names(::Any) = nothing

"""
    struct AllObservations
        recordings::Vector{Any}
        param_depend::_PARAM_DEPEND_TYPE
        idx_to_param::Dict{Int64,Symbol}
        law_depend::_LAW_DEPEND_TYPE
        obs_depend::_OBS_DEPEND_TYPE
    end

A struct gathering multiple observations of a diffusion processes. Additionaly,
the interdependence structure between parameters shared between various
diffusions laws used to generate the recorded data is kept. `recordings`
collects all recordings, `param_depend` is a dictionary with keys—parameter
labels—and values—vectors with entries that list which laws and observations
depend on a corresponding parameter. `idx_to_param` for numbers going from 1 to
`number-of-parameters` associates a parameter label. `law_depend` gives for each
law in `recordings` a list of parameters that it depends on (with `global_idx`
specifying the index of a parameter as encoded by `idx_to_param`, `pname` its
name as encoded internally by the law and `local_idx` the position of a
parameter as encoded internally by the law). `obs_depend` does the same as
`law_depend`, but for each observation.


    AllObservations(;P=nothing, obs=nothing, t0=nothing, x0_prior=nothing)

Default constructor creating either an empty `AllObservations` object,
or initiating it immediately with a single recording where the target comes
from the law `P`, the observations are stored in `obs` and the observed
process was started at time `t0` from som position which we put a prior on
`x0_prior`.

    AllObservations(recording::NamedTuple)

Constructor creating an `AllObservations` object and initiating it
immediately with a single recording where the target comes
from the law `recording.P`, the observations are stored in `recording.obs`
and the starting point is at time `recording.t0` and has a prior `x0_prior`.

"""
struct AllObservations
    recordings::Vector{Any}
    param_depend::_PARAM_DEPEND_TYPE
    idx_to_param::Dict{Int64,Symbol}
    law_depend::_LAW_DEPEND_TYPE
    obs_depend::_OBS_DEPEND_TYPE

    function AllObservations(;
            P=nothing,
            obs=nothing,
            t0=nothing,
            x0_prior=nothing
        )
        nothing_passed = all([v===nothing for v in [P, obs, t0, x0_prior]])
        nothing_passed && return new{}(
            [],
            _PARAM_DEPEND_TYPE(),
            Dict{Int64,Symbol}(),
            _LAW_DEPEND_TYPE(undef,0),
            _OBS_DEPEND_TYPE(undef,0)
        )
        @assert all([v!=nothing for v in [P, obs, t0, x0_prior]])
        AllObservations((P=P,obs=obs,t0=t0,x0_prior=x0_prior))
    end

    function AllObservations(recording::NamedTuple)
        check_recording_format(recording)
        new{}(
            [recording],
            _PARAM_DEPEND_TYPE(),
            Dict{Int64,Symbol}(),
            _LAW_DEPEND_TYPE(undef,0),
            _OBS_DEPEND_TYPE(undef,0)
        )
    end
end

"""
    check_recording_format(::T) where T<:NamedTuple

Check whether the namedtuple has fields `P`, `obs`, `t0` and `x0_prior` that
each recording must have.
"""
function check_recording_format(::T) where T<:NamedTuple
    @assert hasfield(T, :P)
    @assert hasfield(T, :obs)
    @assert hasfield(T, :t0)
    @assert hasfield(T, :x0_prior)
end

"""
    add_recording!(all_obs::AllObservations, recording::NamedTuple)

Add a new recording `recording` to observations container `all_obs`.
"""
function add_recording!(all_obs::AllObservations, recording::NamedTuple)
    check_recording_format(recording)
    append!(all_obs.recordings, [recording])
end

"""
    add_dependency!(all_obs::AllObservations, dep::Dict)

Add a dependency structure `dep` between parameters shared across various laws
and observations used to generate various recordings stored in an observations
container `all_obs`.
"""
function add_dependency!(all_obs::AllObservations, dep::Dict)
    existing_keys = keys(all_obs.param_depend)
    for key in keys(dep)
        if key in existing_keys
            println(
                "Warning! depenendency for $key is already defined. ",
                "Appending with new info..."
            )

        else
            all_obs.param_depend[key] = _PARAM_DEPEND_ENTRY_TYPE(undef, 0)
            num_entries = length(keys(all_obs.idx_to_param))
            all_obs.idx_to_param[num_entries+1] = key
        end
        for v in dep[key]
            push!(
                all_obs.param_depend[key],
                format_dep_entry(Val(v[2]), all_obs.recordings[v[1]], v)
            )
        end
    end
end

"""
    format_dep_entry(P, entry)

Format an entry pointing to a specific parameter in a specific law used for a
specific recording so that it encodes recording index `rec_idx`, parameter index
`param_idx` and parameter name `param_name` of the pointing to position.
"""
format_dep_entry(::Val{true}, rec, entry) = format_law_dep_entry(rec.P, Tuple(entry))

#TODO implement this is for observations...
format_dep_entry(::Val{false}, rec, entry) = nothing

"""
    format_dep_entry(P, entry::Tuple{Int64,Int64})

Infer recording index `rec_idx`, parameter index `param_idx` and parameter name
`param_name` from the pair that lists recording index and parameter index within
the law that was used for that recording.
"""
function format_law_dep_entry(P, entry::Tuple{Int64,Bool,Int64})
    p_names = parameter_names(P)
    r_idx, _, p_idx = entry
    @assert length(p_names) >= p_idx

    (
        rec_idx=r_idx,
        law_else_obs=true,
        obs_idx=-1,
        param_idx=p_idx,
        param_name=p_names[p_idx]
    )
end

"""
    format_dep_entry(P, entry::Tuple{Int64,Symbol})

Infer recording index `rec_idx`, parameter index `param_idx` and parameter name
`param_name` from the pair that lists recording index and parameter name within
the law that was used for that recording.
"""
function format_law_dep_entry(P, entry::Tuple{Int64,Bool,Symbol})
    p_names = parameter_names(P)
    r_idx, _, p_name = entry
    @assert p_name in p_names
    p_idx = argmax(p_names .== p_name)

    (
        rec_idx=r_idx,
        law_else_obs=true,
        obs_idx=-1,
        param_idx=p_idx,
        param_name=p_name
    )
end

"""
    format_dep_entry(P, entry::Tuple{Int64,Int64,Symbol})

Make sure that recording index `rec_idx`, parameter index `param_idx` and
parameter name `param_name` make sense and are formatted correctly.
"""
function format_law_dep_entry(P, entry::Tuple{Int64,Bool,Int64,Symbol})
    p_names = parameter_names(P)
    r_idx, _, p_idx, p_name = entry
    @assert p_name in p_names
    @assert length(p_names) >= p_idx
    @assert p_names[p_idx] == p_name

    (
        rec_idx=r_idx,
        law_else_obs=true,
        obs_idx=-1,
        param_idx=p_idx,
        param_name=p_name
    )
end

function format_law_dep_entry(P, entry::Tuple{Int64,Bool,Int64,Int64,Symbol})
    format_law_dep_entry(P, (entry[[1,2,4,5]]...,))
end

"""
    initialize(all_obs::AllObservations)

Split the recordings at the times of full observations to make full use of the
Markov property (and make the code readily parallelisable). Introduce all
parameters that were not mentioned in the current dependency dictionary. Create
dictionaries that allow for efficient retreival of all laws and observations
that depend on any specified parameter
"""
function initialize(all_obs::AllObservations)
    full_param_depend = fill_dependency_for_unspec_params(all_obs)
    out = AllObservations()
    old_to_new_idx = Dict{Int64,Vector{Int64}}()
    old_to_new_obs_idx = Dict{Int64,Dict{Int64,Int64}}()
    counter = 1

    for (rec_idx, recording) in enumerate(all_obs.recordings)
        counter = split_recording!(
            rec_idx,
            recording,
            counter,
            out,
            old_to_new_idx,
            old_to_new_obs_idx
        )
    end
    new_param_dependence!(out, full_param_depend, old_to_new_idx, old_to_new_obs_idx)

    obs_and_law_dependence_table!(out)
    out, old_to_new_idx
end

"""
    fill_dependency_for_unspec_params(all_obs::AllObservations)

Fill the `all_obs.depen_param` dictionary with all parameters that are not
shared between recordings.
"""
function fill_dependency_for_unspec_params(all_obs::AllObservations)
    accounted_for_entries = Iterators.flatten(values(all_obs.param_depend))
    new_entries = _PARAM_DEPEND_TYPE()
    for (rec_idx, recording) in enumerate(all_obs.recordings)
        p_names = parameter_names(recording.P)
        p_obs_names = [parameter_names(obs) for obs in recording.obs]
        for (p_idx, p_name) in enumerate(p_names)
            entry = (
                rec_idx = rec_idx,
                law_else_obs = true,
                obs_idx = -1,
                param_idx = p_idx,
                param_name = p_name,
            )
            if !(entry in accounted_for_entries)
                new_entries[Symbol("REC$rec_idx","_", p_name)] = [entry]
            end
        end
        for (obs_idx, p_obs_name) in enumerate(p_obs_names)
            for (p_idx, p_name) in enumerate(p_obs_name)
                entry = (
                    rec_idx = rec_idx,
                    law_else_obs = false,
                    obs_idx = obs_idx,
                    param_idx = p_idx,
                    param_name = p_name,
                )
                if !(entry in accounted_for_entries)
                    new_entries[Symbol(
                        "REC$(rec_idx)_OBS$(obs_idx)_",
                        p_name
                    )] = [entry]
                end
            end
        end
    end
    merge(all_obs.param_depend, new_entries)
end


"""
    split_recording!(
            recording_idx,
            recording,
            counter,
            out::AllObservations,
            old_to_new_idx,
            old_to_new_obs_idx,
        )

Split a single record `recording` at the times of full observations. Save new,
splitted recordings in the struct `out.` Keep account of the changed indices
of the recordings for the `recording index <---> parameter dependence` pairs by
updating a suitable dictionary `old_to_new_idx`, starting the new recording's
index at an offset `counter`.
"""
function split_recording!(
        recording_idx,
        recording,
        counter,
        out::AllObservations,
        old_to_new_idx,
        old_to_new_obs_idx,
    )
    t0 = recording.t0
    x0_prior = deepcopy(recording.x0_prior)
    N = length(recording.obs)
    start_idx = 1

    for i in 1:N
        obs = recording.obs[i]
        if (obs.full_obs || i == N)
            new_recording = (
                P = deepcopy(recording.P),
                obs = deepcopy(recording.obs[start_idx:i]),
                t0 = t0,
                x0_prior = x0_prior,
            )
            add_recording!(out, new_recording)

            if haskey(old_to_new_idx, recording_idx)
                push!(old_to_new_idx[recording_idx], counter)
            else
                old_to_new_idx[recording_idx] = [counter]
            end

            if !haskey(old_to_new_obs_idx, recording_idx)
                old_to_new_obs_idx[recording_idx] = Dict{Int64,Int64}()
                old_to_new_obs_idx[recording_idx][-1] = -1
            end
            for j in start_idx:i
                old_to_new_obs_idx[recording_idx][j] = j-start_idx+1
            end

            counter += 1
            start_idx = i+1
            t0 = obs.t
            x0_prior = KnownStartingPt(obs.obs)
        end
    end
    counter
end

"""
    new_param_dependence!(out, old_dep, old_to_new_idx)

Define a new parameter dependence structure by using an old parameter dependence
saved in `old_dep` and deducing the changed indices of affected recording by
following the `old_to_new_idx` dictionary. The new dependency is saved directly
to `out` structure.
"""
function new_param_dependence!(out, old_dep, old_to_new_idx, old_to_new_obs_idx)
    new_dep = _PARAM_DEPEND_TYPE()
    for key in keys(old_dep)
        new_entry = _PARAM_DEPEND_ENTRY_TYPE(undef, 0)
        for old_connector in old_dep[key]
            new_connectors = [
                (
                    rec_idx = new_rec_idx,
                    law_else_obs = old_connector.law_else_obs,
                    obs_idx = old_to_new_obs_idx[old_connector.rec_idx][old_connector.obs_idx],
                    param_idx = old_connector.param_idx,
                    param_name = old_connector.param_name,
                )
                for new_rec_idx in old_to_new_idx[old_connector.rec_idx]
            ]
            append!(new_entry, collect(new_connectors))
        end
        new_dep[key] = new_entry
    end
    add_dependency!(out, new_dep)
end

function get_dep(all_obs::AllObservations, coord)
    p_name = all_obs.idx_to_param[coord]
    dep = all_obs.param_depend[p_name]
end

"""
    obs_and_law_dependence_table!(all_obs::AllObservations)

Create containers that associate to each law an observation a list of parameters
that they depend on.
"""
function obs_and_law_dependence_table!(all_obs::AllObservations)
    all_global_coords = sort(collect(keys(all_obs.idx_to_param))) # should be [1,2,...,N] say

    num_rec = length(all_obs.recordings)
    resize!(all_obs.law_depend, num_rec)
    resize!(all_obs.obs_depend, num_rec)

    for (i,r) in enumerate(all_obs.recordings)
        all_obs.law_depend[i] = construct_law_i_dependency(all_obs, all_global_coords, i)
        num_obs_i = length(r.obs)
        all_obs.obs_depend[i] = _LAW_DEPEND_TYPE(undef, num_obs_i)
        for j in 1:num_obs_i
            all_obs.obs_depend[i][j] = construct_obs_ij_dependency(all_obs, all_global_coords, i, j)
        end
    end
end

function construct_law_i_dependency(all_obs::AllObservations, coords, i)
    law_i_global_coords_idx = filter(
        c_i->any(
            x->(x.rec_idx == i && x.law_else_obs),
            get_dep(all_obs, coords[c_i])
        ),
        1:length(coords)
    )

    law_i_relevant = map(
        c_i->filter(
            x->(x.rec_idx == i && x.law_else_obs),
            get_dep(all_obs, coords[c_i])
        ),
        law_i_global_coords_idx
    )
    @assert all(length.(law_i_relevant) .== 1)
    law_i_relevant = first.(law_i_relevant)

    map(
        x->(
            global_idx = coords[x[2]],
            pname = x[1].param_name,
            local_idx = x[1].param_idx,
        ),
        zip(law_i_relevant, law_i_global_coords_idx)
    )
end

function construct_obs_ij_dependency(all_obs::AllObservations, coords, i, j)
    obs_ij_global_coords_idx = filter(
        c_i->any(
            x->(x.rec_idx == i && !x.law_else_obs && x.obs_idx == j),
            get_dep(all_obs, coords[c_i])
        ),
        1:length(coords)
    )

    obs_ij_relevant = map(
        c_i->filter(
            x->(x.rec_idx == i && !x.law_else_obs && x.obs_idx == j),
            get_dep(all_obs, coords[c_i])
        ),
        obs_ij_global_coords_idx
    )
    @assert all(length.(obs_ij_relevant) .== 1)
    obs_ij_relevant = first.(obs_ij_relevant)

    map(
        x->(
            global_idx = coords[x[2]],
            pname = x[1].param_name,
            local_idx = x[1].param_idx,
        ),
        zip(obs_ij_relevant, obs_ij_global_coords_idx)
    )
end
