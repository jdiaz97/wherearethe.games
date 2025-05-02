using TidierVest
using ProgressMeter
include("utils.jl")
include("vals.jl")

Base.@kwdef mutable struct Game
    Name::String = "Unknown" # done
    Country::String = "Unknown" # default
    Description::String = "Unknown" # done
    Thumbnail::String = "Unknown" #done 
    Publisher_Names::String = "Unknown" # done 
    Developer_Names::String = "Unknown"# done
    Platform::String = "Unknown" # done
    Release_Date::String = "Unknown" # done 
    Genre::String = "Unknown" # done
    Steam_Link::String = "Unknown" # default
    Epic_Link::String = "Unknown"
    Playstation_Link::String = "Unknown"
    Xbox_Link::String = "Unknown"
    Switch_Link::String = "Unknown"
    GOG_Link::String = "Unknown"
end

DataFrame(s::Game) = DataFrame([name => [getfield(s, name)] for name in fieldnames(typeof(s))])
DataFrame(games::Vector{Game}) = reduce(vcat,DataFrame.(games))

clean_date(date_string::String) = (date_string == "Coming soon" || !(length(split(date_string)) == 2) || !occursin(",", split(date_string)[2])) ? "To be announced" : date_string
cleanlink(url) = split(url, "?curator")[1]*"/" |> cleanlink2 |> ensure_trailing_slash
cleanlink2(url) = split(url, "/?")[1]
ensure_trailing_slash(str) = endswith(str, "/") ? str : str * "/"

function final_str_platforms(input_string::String)::String
    platforms = [m.match for m in collect(eachmatch(r"Windows|macOS|SteamOS \+ Linux", input_string))]
    finalstr = ""
    for p in platforms
        finalstr = finalstr * p * ", "
    end
    return finalstr[begin:end-2]
end

safe_extract!(func::Function, game::Game, html, default="Unknown") = try func(game, html) catch _ return default end
get_name!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Name = html_elements(h, ".apphub_AppName")[1] |> html_text3), game, html, "Unknown Game")
get_dev!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Developer_Names = html_elements(h, ".dev_row")[1].children[2] |> html_text3), game, html, "Unknown Developer")
get_publisher!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Publisher_Names = html_elements(h, ".dev_row")[2].children[2] |> html_text3), game, html, "Unknown Publisher")
get_release_date!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Release_Date = clean_date((html_elements(h, ".date")|>html_text3)[1])), game, html, "Unknown Release Date")
get_thumbnail!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Thumbnail = html_attrs(html_elements(h, ".game_header_image_full"), "src")[1]), game, html, "No Thumbnail")
get_platform!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Platform = final_str_platforms(get((html_elements(h, ".sysreq_tabs") |> html_text3), 1, "Windows"))), game, html, "Unknown Platform")
get_genre!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Genre = join(unique(html_elements(h, ["div", ".block_content_inner", "span", "a"]) |> html_text3), ", ")), game, html, "No Genre")
get_desc!(::Val{Steam}, game::Game, html) = safe_extract!((g,h) -> (g.Description = (d = replace(html_elements(h, ".game_description_snippet")[1] |> html_text3, "\t" => "", ";" => ",")) |> x -> length(x) > 185 ? x[1:183] * "..." : x), game, html, "No Description")

function fetch_data!(game::Game)
    html = read_html(game.Steam_Link)

    get_name!(Val(Steam), game,html)
    get_dev!(Val(Steam), game,html)
    get_publisher!(Val(Steam), game,html)
    get_desc!(Val(Steam), game,html)
    get_genre!(Val(Steam), game,html)
    get_release_date!(Val(Steam), game,html)
    get_thumbnail!(Val(Steam), game,html)
    get_platform!(Val(Steam), game,html)
    return game
end

function update_data()
    data = CSV.File("data/curators.csv", delim =", ", stringtype = String)    
    listgames::Vector{Game} = []
    
    @showprogress Threads.@threads for row in data
        country = row[:Country]
        println("Processing: "*country)
        listgames = vcat(listgames,get_games(row[:url],country))      
    end

    contributions = CSV.read(IOBuffer(HTTP.get("https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv").body), DataFrame,stringtype=String) |> vals |> df_to_games
    listgames = vcat(listgames, contributions)

    println("Starting massive web scraping")
    @showprogress Threads.@threads for i in eachindex(listgames)
        listgames[i] = listgames[i] |> fetch_data!
    end

    df = listgames |> DataFrame
    sort!(df, :Name)
    for unique_country in unique(df[:, :Country])
        save_data(df[df[:, :Country].==unique_country, :],unique_country)
    end
end

function pre_compile()
    get_games("https://store.steampowered.com/curator/25510407-Games-Devs-from-Denmark/#browse","Denmark") .|> fetch_data! |> DataFrame
    return nothing 
end
