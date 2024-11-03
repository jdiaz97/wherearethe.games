include("scraper2.jl")

url = "https://store.steampowered.com/curator/40000720-dkgame/#browse"
country = "Denmark"
df = create_df(url,country,true) 