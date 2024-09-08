include("scraper.jl")

c = "Chile"
df = scrape_mentor("data/"*c*".html",c); save_data(df,c)

c = "Denmark"
df = scrape_mentor("data/"*c*".html",c); save_data(df,c)
