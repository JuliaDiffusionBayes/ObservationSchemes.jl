using Documenter, ObservationSchemes

makedocs(;
    modules=[ObservationSchemes],
    format=Documenter.HTML(),
    pages=[
        "Home" => "index.md",
    ],
    repo="https://github.com/JuliaDiffusionBayes/ObservationSchemes.jl/blob/{commit}{path}#L{line}",
    sitename="ObservationSchemes.jl",
    authors="Sebastiano Grazzi, Frank van der Meulen, Marcin Mider, Moritz Schauer",
    assets=String[],
)

deploydocs(;
    repo="github.com/JuliaDiffusionBayes/ObservationSchemes.jl",
)
