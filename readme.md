# Where are the games?

Website concept

# The Julia part

```julia
# We want to scrape the list of a steam curator
# Function to calculate factorial of a number
url = "https://store.steampowered.com/curator/25113200-Videojuegos-Made-In-Chile/#browse"
country = "Chile"

# First option,
html = full_html(url) # not yet implemented, it's hard to scroll.
# or 
html = read_html(open("data.html"));
list::Vector{String} = gamelist_from_curatorlist(html)
df = scrape_mentor2(list, country) # given every game on the list, we are gonna get the data
CSV.write(country*".csv",df);

# Second option, with files.
df = scrape_mentor("previous_url.html",country)
CSV.write(country*".csv",df)

```

