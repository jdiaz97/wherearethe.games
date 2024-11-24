# Where are the games?

Website concept

# The Julia part

```julia
include("julia/pipelines.jl")

url = "https://store.steampowered.com/curator/25113200-Videojuegos-Made-In-Chile/#browse"
country = "Chile"
create_df(url,country) |> process_df

# done, you scraped all the data, put it in nice CSVs, did all the validations and checks!

# also you could just

update_data()

# you scraped a bunch of internet data, including the contributions that were done on the website
```

