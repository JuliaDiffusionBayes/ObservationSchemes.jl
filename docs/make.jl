using Documenter, ObservationSchemes

makedocs(;
    modules=[ObservationSchemes],
    format=Documenter.HTML(
        mathengine = Documenter.MathJax(
            Dict(
                :TeX => Dict(
                    :equationNumbers => Dict(
                        :autoNumber => "AMS"
                    ),
                    :Macros => Dict(
                        :dd => "{\\textrm d}",
                        :RR => "\\mathbb{R}",
                        :wt => ["\\widetilde{#1}", 1]
                    ),
                )
            )
        ),
        collapselevel = 1,
    ),
    pages=[
        "Home" => "index.md",
        "Get started" => joinpath("get_started", "overview.md"),
        "User manual" => Any[
            "A single observation" => joinpath("manual", "single_observation.md"),
            "Priors over starting points" => joinpath("manual", "start_pt_prior.md"),
            "Multiple observations" => joinpath("manual", "multiple_observations.md"),
            "Observation schemes" => joinpath("manual", "observation_schemes.md"),
            "Utility fuctions" => joinpath("manual", "utility_functions.md"),
        ],
        "How to..." => Any[
            "... ergonomically deal with simple observation schemes?" => joinpath("how_to_guides", "simple_os.md"),
            "... define custom priors over starting points?" => joinpath("how_to_guides", "custom_priors.md"),
            "... define custom observation schemes?" => joinpath("how_to_guides", "custom_os.md"),
            "... work with dataframes?" => joinpath("how_to_guides", "dataframes.md"),
            "... read data directly from a `.csv` file?" => joinpath("how_to_guides", "csv_files.md"),
            "... save decorated data to a file?" => joinpath("how_to_guides", "save_to_files.md"),
            "... deal with stochastic processes other than diffusions?" => joinpath("how_to_guides", "other_processes.md"),
            "... leverage `AllObservations` to efficiently update parameters?" => joinpath("how_to_guides", "update_params.md"),
        ],
        "Tutorials" => Any[
            "(TODO) Single path" => joinpath("tutorials", "single_path.md"),
            "(TODO) Multiple paths" => joinpath("tutorials", "multi_paths.md"),
            "(TODO) Multiple paths differently observed" => joinpath("tutorials", "multi_paths_diff_observ.md"),
            "(TODO) Mixed effect models" => joinpath("tutorials", "mixed_effect_models.md"),
            "(TODO) Observations of HMM driven by ARCH(1)" => joinpath("tutorials", "hmm.md"),
        ],
        "Index" => "module_index.md",
    ],
    repo="https://github.com/JuliaDiffusionBayes/ObservationSchemes.jl/blob/{commit}{path}#L{line}",
    sitename="ObservationSchemes.jl",
    authors="Sebastiano Grazzi, Frank van der Meulen, Marcin Mider, Moritz Schauer",
    #assets=String[],
)

deploydocs(;
    repo="github.com/JuliaDiffusionBayes/ObservationSchemes.jl",
)
