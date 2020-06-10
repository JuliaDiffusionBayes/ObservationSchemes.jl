module ObservationSchemes

    using LinearAlgebra, StaticArrays
    using GaussianDistributions, Random
    using Distributions, OrderedCollections

    import GaussianDistributions: whiten, unwhiten

    # these are used throughout the suite, they need to be put into one place only
    # and imported from there.
    ismutable(el) = ismutable(typeof(el))
    ismutable(::Type) = Val(false)
    ismutable(::Type{<:Array}) = Val(true)

    include("starting_point_priors.jl")
    include("first_passage_times.jl")
    include("observations_common.jl")
    include("observations_linear_gaussian.jl")
    include("observations_general.jl")
    include("all_observations.jl")
    include("all_observations_utilities.jl")
    include("obs_scheme.jl")
    include("convenience_functions.jl")

    # starting_point_priors.jl
    export KnownStartingPt, GsnStartingPt

    # first_passage_times.jl
    export NoFirstPassageTimes, FirstPassageTimeInfo

    # observations_lienar_gaussian.jl
    export LinearGsnObs, fpt_info

    # observations_general.jl
    export GeneralObs

    # all_observations.jl
    export AllObservations, add_recording!, add_recordings!, add_dependency!
    export initialize

    # obs_scheme.jl
    export ObsScheme, load_data

    # convenience_functions.jl
    export package, build_recording, num_recordings, num_obs

    export print_parameters

end # module
