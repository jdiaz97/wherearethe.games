include("scraper.jl")

c = "Chile"
df = scrape_mentor("data/chile.html",c)
save_data(df,"Chile")

