#=
    Defines a container for multiple recordings of discrete-time observations
    of diffusion processes. The main object is `AllObservations`
=#
const _PARAM_DEPEND_ENTRY_TYPE = Vector{Pair{Int64, Symbol}}
const _OBS_DEPEND_ENTRY_TYPE = Vector{Tuple{Int64,Int64,Int64}}

const _PARAM_DEPEND_TYPE = Dict{Symbol,_PARAM_DEPEND_ENTRY_TYPE}
const _OBS_DEPEND_TYPE = Dict{Symbol,_OBS_DEPEND_ENTRY_TYPE}

const _PARAM_REV_DEPEND_TYPE = Vector{Vector{Tuple{Symbol,Symbol}}}
const _OBS_REV_DEPEND_TYPE = Vector{Vector{Vector{Tuple{Symbol,Int64}}}}

#NOTE this function must be overwritten from `Main`.
var_parameter_names(::Any) = nothing

"""
    struct AllObservations
        recordings::Vector{Any}
        param_depend::Dict{Symbol,Vector{Pair{Int64, Symbol}}}
        obs_depend::Dict{Symbol,Vector{Tuple{Int64,Int64,Int64}}}
        param_depend_rev::Vector{Vector{Tuple{Symbol,Symbol}}}
        obs_depend_rev::Vector{Vector{Vector{Tuple{Symbol,Int64}}}}
    end

A struct gathering multiple observations of a diffusion processes. Additionaly,
the interdependence structure between parameters shared between various
diffusions laws used to generate the recorded data is kept. `recordings`
collects all recordings, `param_depend` is a dictionary with keys—parameter
labels—and values—vectors with entries that list which laws depend on a
corresponding parameter. `obs_depend` does the same but for observations.
`param_depend_rev` gives for each law a list of (variable) parameters it depends
on and `obs_depend_rev` does the same but for the observations.

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
    obs_depend::_OBS_DEPEND_TYPE
    param_depend_rev::_PARAM_REV_DEPEND_TYPE
    obs_depend_rev::_OBS_REV_DEPEND_TYPE

    function AllObservations(;
            P=nothing,
            obs=nothing,
            t0=nothing,
            x0_prior=nothing
        )
        nothing_passed = all(v->v===nothing, [P, obs, t0, x0_prior])
        nothing_passed && return new{}(
            [],
            _PARAM_DEPEND_TYPE(),
            _OBS_DEPEND_TYPE(),
            _PARAM_REV_DEPEND_TYPE(undef,0),
            _OBS_REV_DEPEND_TYPE(undef,0)
        )
        @assert all(v->v!=nothing, [P, obs, t0, x0_prior])
        AllObservations((P=P,obs=obs,t0=t0,x0_prior=x0_prior))
    end

    function AllObservations(recording::NamedTuple)
        check_recording_format(recording)
        new{}(
            [recording],
            _PARAM_DEPEND_TYPE(),
            _OBS_DEPEND_TYPE(),
            _PARAM_REV_DEPEND_TYPE(undef,0),
            _OBS_REV_DEPEND_TYPE(undef,0)
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
    existing_keys_param = keys(all_obs.param_depend)
    existing_keys_obs = keys(all_obs.obs_depend)
    for key in keys(dep)
        add_a_single_dependency!(
            all_obs,
            key,
            dep[key],
            existing_keys_param,
            existing_keys_obs
        )
    end
end

function add_a_single_dependency!(
        all_obs::AllObservations,
        key,
        val::Vector{Tuple{Int64, Int64, Int64}},
        ::Any,
        existing_keys
    )
    if key in existing_keys
        println(
            "Warning! depenendency for $key is already defined. ",
            "Appending with new info..."
        )
    else
        all_obs.obs_depend[key] = _OBS_DEPEND_ENTRY_TYPE(undef, 0)
    end
    push!(all_obs.obs_depend[key], val)
end

function add_a_single_dependency!(
        all_obs::AllObservations,
        key,
        val::Vector{<:Union{Pair{Int64, Symbol}, Tuple{Int64, Symbol}}},
        existing_keys,
        ::Any
    )
    if key in existing_keys
        println(
            "Warning! depenendency for $key is already defined. ",
            "Appending with new info..."
        )
    else
        all_obs.param_depend[key] = _PARAM_DEPEND_ENTRY_TYPE(undef, 0)
    end
    foo(x)=Pair(x...)
    append!(all_obs.param_depend[key], foo.(val))
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
    full_p_dep, full_o_dep = fill_dependency_for_unspec_params_and_obs(all_obs)
    out = AllObservations()
    old_to_new_idx = Dict{Int64,Vector{Int64}}()
    old_to_new_obs_idx = Dict{Tuple{Int64,Int64},Tuple{Int64,Int64}}()
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
    new_param_and_obs_dependence!(
        out,
        full_p_dep,
        full_o_dep,
        old_to_new_idx,
        old_to_new_obs_idx
    )
    reverse_param_and_obs_dep!(out)
    out, old_to_new_idx
end

"""
    fill_dependency_for_unspec_params(all_obs::AllObservations)

Fill the `all_obs.depen_param` dictionary with all parameters that are not
shared between recordings.
"""
function fill_dependency_for_unspec_params_and_obs(all_obs::AllObservations)
    new_param_entries = fill_dependency_for_unspec_params(all_obs)
    new_obs_entries = fill_dependency_for_unspec_obs(all_obs)
    (
        merge(all_obs.param_depend, new_param_entries),
        merge(all_obs.obs_depend, new_obs_entries)
    )
end

function fill_dependency_for_unspec_params(all_obs::AllObservations)
    accounted_for_entries = Iterators.flatten(values(all_obs.param_depend))
    new_entries = _PARAM_DEPEND_TYPE()

    for (rec_idx, recording) in enumerate(all_obs.recordings)
        # retreive all of the variable parameter names
        p_names = var_parameter_names(recording.P)
        for p_name in p_names
            entry = (rec_idx => p_name)
            if !(entry in accounted_for_entries)
                new_entries[Symbol("REC$(rec_idx)_", p_name)] = [entry]
            end
        end
    end
    new_entries
end

function fill_dependency_for_unspec_obs(all_obs::AllObservations)
    accounted_for_entries = Iterators.flatten(values(all_obs.obs_depend))
    new_entries = _OBS_DEPEND_TYPE()

    for (rec_idx, recording) in enumerate(all_obs.recordings)
        for (obs_idx, obs) in enumerate(recording.obs)
            obs_positions = var_parameter_pos(obs)
            for obs_pos in obs_positions
                entry = (rec_idx, obs_idx, obs_pos)
                if !(entry in accounted_for_entries)
                    new_entries[Symbol(
                        "REC$(rec_idx)_OBS$(obs_idx)_",
                        obs_pos
                    )] = [entry]
                end
            end
        end
    end
    new_entries
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

            for j in start_idx:i
                old_to_new_obs_idx[(recording_idx, j)] = (counter, j-start_idx+1)
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
    new_param_and_obs_dependence!(
        out,
        old_p_dep,
        old_o_dep,
        old_to_new_idx,
        old_to_new_obs_idx
    )

TODO refresh Define a new parameter dependence structure by using an old parameter dependence
saved in `old_dep` and deducing the changed indices of affected recording by
following the `old_to_new_idx` dictionary. The new dependency is saved directly
to `out` structure.
"""
function new_param_and_obs_dependence!(
        out,
        old_p_dep,
        old_o_dep,
        old_to_new_idx,
        old_to_new_obs_idx
    )
    new_p_dep = new_param_dependence!(old_p_dep, old_to_new_idx)
    new_o_dep = new_obs_dependence!(old_o_dep, old_to_new_obs_idx)
    add_dependency!(out, new_p_dep)
    add_dependency!(out, new_o_dep)
end

"""
    new_param_dependence!(old_dep, old_to_new_idx)

Create a new interdependency dictionary for the parameters from the old one
`old_dep` and the dictionary `old_to_new_idx` that kept track of the changes.

# Examples
```julia
old_dep = Dict(
    :A => [(1, :a), (2, :a1)],
    :B => [(1, :b), (3, :bbb)],
)
old_to_new_idx = Dict(
    1 => [1, 2], # observation 1 was split into two
    2 => [3, 4, 5], # observation 2 was split into three
    3 => [6],
)

new_dep = new_param_dependence!(old_dep, old_to_new_idx)

new_dep == Dict(
    :A => [1=>:a, 2=>:a, 3=>:a1, 4=>:a1, 5=>:a1],
    :B => [1=>:b, 2=>:b, 6=>:bbb],
)
```
"""
function new_param_dependence!(old_dep, old_to_new_idx)
    new_dep = _PARAM_DEPEND_TYPE()
    for key in keys(old_dep)
        new_entry = _PARAM_DEPEND_ENTRY_TYPE(undef, 0)
        for old_connector in old_dep[key]
            old_rec_idx, p_symbol = old_connector
            new_connectors = [
                (new_rec_idx => p_symbol)
                for new_rec_idx in old_to_new_idx[old_rec_idx]
            ]
            append!(new_entry, collect(new_connectors))
        end
        new_dep[key] = new_entry
    end
    new_dep
end

"""
    new_obs_dependence!(old_dep, old_to_new_idx)

Create a new interdependency dictionary for the observations from the old one
`old_dep` and the dictionary `old_to_new_idx` that kept track of the changes.

# Example
```julia
old_dep = Dict(
    :A => [(1, 2, 1), (1, 3, 2), (2, 1, 1)],
    :B => [(2, 2, 2), (3, 2, 1)],
)
old_to_new_idx = Dict(
    (1,1) => (1, 1), # obs (1,1) becomes (1,1)
    (1,2) => (1, 2),
    (1,3) => (2, 1), # obs (1,3) becomes (2,1)
    (2,1) => (3, 1),
    (2,2) => (4, 1),
    (2,3) => (5, 1),
    (3,1) => (6, 1),
    (3,2) => (6, 2),
)

new_dep = new_obs_dependence!(old_dep, old_to_new_idx)

new_dep == Dict(
    :A => [(1, 2, 1), (2, 1, 2), (3, 1, 1)],
    :B => [(4, 1, 2), (6, 2, 1)]
)
```
"""
function new_obs_dependence!(old_dep, old_to_new_idx)
    new_dep = _OBS_DEPEND_TYPE()
    for key in keys(old_dep)
        new_entry = _OBS_DEPEND_ENTRY_TYPE(undef, 0)
        for old_connector in old_dep[key]
            old_rec_idx, old_obs_idx, obs_idx = old_connector
            new_rec_idx, new_obs_idx = old_to_new_idx[(old_rec_idx, old_obs_idx)]
            append!(new_entry, [(new_rec_idx, new_obs_idx, obs_idx)])
        end
        new_dep[key] = new_entry
    end
    new_dep
end

function reverse_param_and_obs_dep!(out)
    reverse_param_dep!(out)
    reverse_obs_dep!(out)
end

function reverse_param_dep!(out)
    recs = out.recordings
    resize!(out.param_depend_rev, length(recs))
    for (i, rec) in enumerate(recs)
        out.param_depend_rev[i] = Tuple{Symbol,Symbol}[]
    end
    for key in keys(out.param_depend)
        vals = out.param_depend[key]
        for val in vals
            push!(out.param_depend_rev[val[1]], (key, val[2]))
        end
    end
end

function reverse_obs_dep!(out)
    recs = out.recordings
    resize!(out.obs_depend_rev, length(recs))
    for (i, rec) in enumerate(recs)
        N = length(rec.obs)
        out.obs_depend_rev[i] = Vector{Vector{Tuple{Symbol,Int64}}}(undef, N)
        for j in 1:N
            out.obs_depend_rev[i][j] = Tuple{Symbol,Int64}[]
        end
    end
    for key in keys(out.obs_depend)
        vals = out.obs_depend[key]
        for val in vals
            push!(out.obs_depend_rev[(val[1], val[2])], (key, val[3]))
        end
    end
end
