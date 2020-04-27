#===============================================================================

    Convenience functions for:
        ✔   packaging together auxiliary objects and observations so
            that the shapes of the two match
        ✔   building recordrings that share the observation schemes

===============================================================================#
function package(objs::AbstractArray, all_obs::AllObservations)
    N = length(objs)
    @assert N == length(all_obs.recordings)
    packaged = []
    for i in 1:N
        push!(packaged, package(objs[i], all_obs.recordings[i]))
    end
    packaged
end

function package(objs::AbstractArray, recording::NamedTuple)
    length(objs) == length(recording.obs) && return objs
    @assert length(objs) == 1
    num_segments = length(recording.obs)
    [deepcopy(obj[1]) for _ in 1:num_segments]
end

function package(obj, recording::NamedTuple)
    num_segments = length(recording.obs)
    [deepcopy(obj) for _ in 1:num_segments]
end

function package(objs::AbstractArray, old_to_new_idx::Dict, all_obs::AllObservations)
    N = length(objs)
    @assert N == length(keys(old_to_new_idx))
    packaged = []
    counter = 1
    for i in 1:N
        for j in 1:length(old_to_new_idx[i])
            num_segments = length(all_obs.recordings[counter].obs)
            push!(packaged, [deepcopy(objs[i]) for _ in 1:num_segments])
            counter += 1
        end
    end
    packaged
end

function package(obj, all_obs::AllObservations)
    N = length(all_obs.recordings)
    packaged = []
    for i in 1:N
        num_segments = length(all_obs.recordings[i].obs)
        push!(packaged, [deepcopy(obj) for _ in 1:num_segments])
    end
    packaged
end

function build_recording(
        ::Type{K}, tt, observs::Vector, P, t0, x0_prior; kwargs...
    ) where K
    (
        P = P,
        obs = [K(t, obs; kwargs...) for (t,obs) in zip(tt, observs)],
        t0 = t0,
        x0_prior = x0_prior,
    )
end

function setup_time_grids(
        all_obs::AllObservations,
        dt=0.01,
        τ=identity,
        eltype=Float64,
        already_arranged_tt=nothing
    )
    N = length(all_obs.recordings)
    already_arranged_tt === nothing || (
        @assert legnth(already_arranged_tt) == length(all_obs.recordings);
        @assert all([
            length(already_arranged_tt[i]) == length(all_obs.recordings[i].obs)
            for i in 1:N
        ]);
        return already_arranged_tt
    )

    arranged_tt = map(1:N) do i
        _dt = _idx_if_array(dt, i)
        _τ = _idx_if_array(τ, i)
        _eltype = _idx_if_array(eltype, i)

        setup_time_grids(all_obs.recordings[i], _dt, _τ, _eltype)
    end
    arranged_tt
end

_idx_if_array(x, i) = typeof(x) <: AbstractArray ? x[i] : x


function setup_time_grids(
        recording::NamedTuple,
        dt=0.01,
        τ=identity,
        eltype=Float64,
        already_arranged_tt=nothing
    )
    N = length(recording.obs)
    already_arranged_tt === nothing || (
        @assert length(already_arranged_tt) == length(recordings.obs);
        return already_arranged_tt
    )
    arranged_tt = map(1:N) do i
        _dt = _idx_if_array(dt, i)
        _τ = _idx_if_array(τ, i)
        _eltype = _idx_if_array(eltype, i)

        _t0 = i == 1 ? recording.t0 : recording.obs[i-1].t
        _T = recording.obs[i].t
        setup_time_grids(_t0, _T, _dt, _τ, _eltype)
    end
    arranged_tt
end

function setup_time_grids(
        t0::Number,
        T::Number,
        dt=0.01,
        τ=identity,
        eltype=Float64,
        already_arranged_tt=nothing
    )
    already_arranged_tt === nothing || (
        @assert already_arranged_tt[1] == t0 && already_arranged_tt[end] == T;
        return already_arranged_tt
    )
    tt = eltype.(τ(collect(t0:dt:T)))
end

num_recordings(all_obs::AllObservations) = length(all_obs.recordings)

function num_obs(all_obs::AllObservations)
    mapreduce(r->length(r.obs), +, all_obs.recordings)
end
