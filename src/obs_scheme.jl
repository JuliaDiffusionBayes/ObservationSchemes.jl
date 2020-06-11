"""
    struct ObsScheme{T}
        obs::T
        pattern::Vector{Int64}
        full_pattern::Vector{Int64}
        mode::Val
    end

A struct `ObsScheme` acts as a template for reading in multiple observations.
- `obs`: contains a list of all possible observation schemes according to which
         the data (that are supposed to be loaded in) were recorded
- `pattern`: specifies the order in which the list of `obs` is supposed to be
             iterated through when reading in successive observations. Usually
             the number of datapoint is larger than the length of `pattern` in
             which case the `pattern` is cycled through repeatedly.
- `full_pattern`: as pattern, but must be of the same length as the loaded in
                  data.
- `mode`: if set to Val{:simple}(), then cycles through `pattern`. Otherwise
          cycles through `full_pattern`.


    ObsScheme(
        obs...;
        pattern=[1:length(obs)...],
        full_pattern=[],
        mode=Val(:simple)
    )

Base constructor.
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
load_data(os::ObsScheme, tt, xx) = load_data(os, collect(zip(tt, xx)))

"""
    load_data(os::ObsScheme, tt_xx)

Same as `load_data(os::ObsScheme, tt, xx)`, but `tt_xx` is a vector of tuples
that pair the observations with their recorded times.

    load_data(os::ObsScheme, tt_xx_filename::String)

Same as above, but `tt_xx` are stored in a .csv file named `tt_xx_filename`,
with each row containing time `t` and its respective observation `x` stored
back-to-back.
"""
load_data(os::ObsScheme, tt_xx) = load_data(
    _pattern_iter(os.mode, os),
    os, tt_xx
)

function _pattern_iter(::Val{:simple}, os::ObsScheme)
    N = length(os.pattern)
    λ(i) = os.pattern[mod1(i, N)]
    λ
end

function _pattern_iter(::Any, os::ObsScheme)
    λ(i) = os.full_pattern[i]
    λ
end

function load_data(λ::Function, os::ObsScheme, tt_xx::Vector)
    observs = [
        obs_from_template(tt_xx[i], os.obs[λ(i)])
        for i in eachindex(tt_xx)
    ]
end

function load_data(λ::Function, os::ObsScheme, tt_xx_filename::String)
    i = 0
    observs = map(eachline(tt_xx_filename)) do line
        i += 1
        tt_xx = parse.(Float64, split(line, ","))
        obs_from_template(
            (tt_xx[1], tt_xx[2:end]),
            os.obs[λ(i)]
        )
    end
    observs
end

function obs_from_template(obs, tmp::LinearGsnObs)
    o = (
        typeof(obs[2]) <: Number && typeof(tmp.obs) <: AbstractArray ?
        [obs[2]] :
        obs[2]
    )
    LinearGsnObs(
        obs[1],
        convert(typeof(tmp.obs), o),
        deepcopy(tmp.L),
        deepcopy(tmp.Σ),
        deepcopy(tmp.μ),
        fpt_info(tmp)(),
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
        fpt_info(tmp)(),
        tmp.g,
        tmp.dist,
        deepcopy(tmp.θ),
        get_tag(tmp)
    )
end


"""
    Base.collect(os::ObsScheme, path, step=1, record_start_pt=false)

Record observations from a raw trajectory `path` according to the observation
scheme `os`. Collect 1 observation for every `step` many points in the raw data.
If `record_start_pt`, then the starting is recorded, otherwise it is omitted.
`path` should have fields `.x` and `.t` with the underlying process and times
respectively.
"""
function Base.collect(os::ObsScheme, path, step=1, omit_first=true)
    i1 = (1+omit_first)
    raw_xx = _prepare_xx(os.mode, os, path.x[1:step:end][i1:end])

    load_data(os, path.t[1:step:end][i1:end], raw_xx)
end

"""
    _prepare_xx(::Val, os::ObsScheme, X)

Cycle through a collection `X` and transform it according to the observation
schemes specified in `os`.
"""
function _prepare_xx(::Val{:simple}, os::ObsScheme, X)
    N = length(os.pattern)
    raw_xx = map(1:length(X)) do i
        rand(os.obs[os.pattern[mod1(i, N)]], X[i])
    end
end

function _prepare_xx(::Any, os::ObsScheme, X)
    @assert length(full_pattern) == length(X)
    raw_xx = map(1:length(X)) do i
        rand(os.obs[os.full_pattern[i]], X[i])
    end
end
