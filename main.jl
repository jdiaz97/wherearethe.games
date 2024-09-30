include("scraper.jl")
include("consoles.jl")
include("contributions.jl")

# countries::Vector{String} = ["Chile","Denmark","Sweden","Finland","Estonia","Austria","Hungary","Poland","Switzerland","Canada"]
# scrape_steam.(countries)

add_contributions()
add_consoles(["Chile"])
deploy()