# Macro Energy
Pipeline written in Julia to collect, standardize, and share annual energy consumption of buildings in the united states for future research.

```julia --project=. p0.jl``` will reference the data found in sources.yml, downloading all of the raw files needed for each city. Next, the bridges directory contains intermediate connectors, which takes data from the city and processes it into a standard format.
