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
        )
    ),
    pages=[
        "Home" => "index.md",
        "Overview" => Any[
            "Observation schemes" => joinpath("overview", "observation_schemes.md"),
            "Priors over starting points" => joinpath("overview", "start_pt_prior.md"),
            "Multiple observations" => joinpath("overview", "multiple_observations.md"),
        ],
        "Index" => "module_index.md",
    ],
    repo="https://github.com/JuliaDiffusionBayes/ObservationSchemes.jl/blob/{commit}{path}#L{line}",
    sitename="ObservationSchemes.jl",
    authors="Sebastiano Grazzi, Frank van der Meulen, Marcin Mider, Moritz Schauer",
    assets=String[],
)

deploydocs(;
    repo="github.com/JuliaDiffusionBayes/ObservationSchemes.jl",
)
