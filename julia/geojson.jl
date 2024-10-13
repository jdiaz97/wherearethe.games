using JSON3
include("../.env")

final_path= "assets/countries.geo.json"
path = "assets/countries-base.geo.json"

data = JSON3.read(path,Dict)

bit::BitVector = BitVector()  # You should initialize it properly
for f in data["features"]
    isit = f["properties"]["name"] in countries
    push!(bit, isit)
end

# mutate
for i in 1:length(data)
    data["features"][i]["properties"]["flag"] = country_flags[data["features"][i]["properties"]["name"]]
end

JSON3.write(final_path,data)