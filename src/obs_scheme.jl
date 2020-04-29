"""
    struct ObsScheme{T}
        obs::T
        pattern::Vector{Int64}
        full_pattern::Vector{Int64}
        mode::Val
    end

Defines an observation scheme for convenient loading of multiple data points at
once and automatically equipping them with observation decorators stored in
`obs` recycling through a set of indeces specified in pattern that pick the
order of observation templates in `obs` that need to be applied.
"""
struct ObsScheme{T}
    obs::T
    pattern::Vector{Int64}
    full_pattern::Vector{Int64}
    mode::Val
end

ObsScheme(obs::T) where T = ObsScheme{Vector{T}}([obs], [1], [], Val(:simple))

function ObsScheme(
        obs...;
        pattern=[1:length(obs)...],
        full_pattern=[],
        mode=Val(:simple)
    )
    obs_v = [obs...]
    T = typeof(obs_v)
    ObsScheme{T}(obs_v, pattern, full_pattern, mode)
end

"""
    load_data(os::ObsScheme, tt, xx)

Decorate the data in `xx` and times of recordings in `tt` according to an
observation scheme template stored in `os`.
"""
load_data(os::ObsScheme, tt, xx) = load_data(os.mode, os, collect(zip(tt, xx)))

"""
    load_data(os::ObsScheme, tt_xx)

Same as `load_data(os::ObsScheme, tt, xx)`, but `tt_xx` is a vector of tuples
that pair the observation with its recorded time.
"""
load_data(os::ObsScheme, tt_xx) = load_data(os.mode, os, tt_xx)

function load_data(::Val{:simple}, os::ObsScheme, tt_xx::Vector)
    N = length(os.pattern)
    observs = [
        obs_from_template(tt_xx[i], os.obs[os.pattern[mod1(i, N)]])
        for i in eachindex(tt_xx)
    ]
end

function load_data(::Any, os::ObsScheme, tt_xx::Vector)
    @assert length(full_pattern) == length(tt_xx)
    observs = [
        obs_from_template(tt_xx[i], os.obs[os.full_pattern[i]])
        for i in eachindex(tt_xx)
    ]
end

function obs_from_template(obs, tmp::LinearGsnObs)
    LinearGsnObs(
        obs[1],
        convert(typeof(tmp.obs), obs[2]),
        deepcopy(tmp.L),
        deepcopy(tmp.Σ),
        deepcopy(tmp.μ),
        fpt_info(tmp),
        tmp.full_obs,
        deepcopy(tmp.θ),
        get_tag(tmp)
    )
end

function obs_from_template(obs, tmp::GeneralObs)
    GeneralObs(
        obs[1],
        convert(typeof(tmp.obs), obs[2]),
        obs_from_template(obs, tmp.lin_obs),
        fpt_info(tmp),
        tmp.g,
        tmp.dist,
        deepcopy(tmp.θ),
        get_tag(tmp)
    )
end
