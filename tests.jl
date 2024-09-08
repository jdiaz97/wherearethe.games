using TidierVest, Gumbo, Cascadia
include("main.jl")

# a = parsehtml(read("scraping/data/1.html",String))

# c = "Chile"
# println(c)
# df = scrape_mentor("scraping/data/cl.html",c)
# CSV.write(c*"file.csv",df, delim =";;")

# c = "Sweden"
# println(c)
# df = scrape_mentor("scraping/data/sw.html",c)
# CSV.write(c*"file.csv",df, delim =";;")

# c = "Denmark"
# println(c)
df = scrape_mentor("scraping/data/dk.html",c)
CSV.write(c*"file.csv",df, delim =";;")

c = "Canada"
println(c)
df = scrape_mentor("scraping/data/ca.html",c)
CSV.write(c*"file.csv",df, delim =";;")

# CSV.write("outputfile.csv",
#             get_game_info2("scraping/data/2.html","https://store.steampowered.com/app/6900/Hitman_Codename_47/","Denmark") |> gameinfo_df, 
#             delim =";;")

# url = "https://store.steampowered.com/curator/32222318-Juegos-hechos-en-Am%25C3%25A9rica-Latina/list/27103/"

c = "Czech"
html = read_html(open("scraping/data/2.html")); list = gamelist_from_curatorlist(html); df = scrape_mentor2(list,c); CSV.write(c*"file.csv",df, delim =";;");

c = "Slovakia"
html = read_html(open("scraping/data/2.html")); list = gamelist_from_curatorlist(html); df = scrape_mentor2(list,c); CSV.write(c*"file.csv",df, delim =";;");
