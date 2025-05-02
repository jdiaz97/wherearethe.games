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
DataFrame(games::Vector{Game}) = reduce(vcat, DataFrame.(games))

clean_date(date_string::String) = (date_string == "Coming soon" || !(length(split(date_string)) == 2) || !occursin(",", split(date_string)[2])) ? "To be announced" : date_string
cleanlink(url) = split(url, "?curator")[1] * "/" |> cleanlink2 |> ensure_trailing_slash
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

try_get(f) =
    try
        f()
    catch
        nothing
    end

get_name!(x::Platform, html)::String = try_get(() -> get_name!(Val(x), html))
get_dev!(x::Platform, html)::String = try_get(() -> get_dev!(Val(x), html))
get_publisher!(x::Platform, html)::String = try_get(() -> get_publisher!(Val(x), html))
get_release_date!(x::Platform, html)::String = try_get(() -> get_release_date!(Val(x), html))
get_thumbnail!(x::Platform, html)::String = try_get(() -> get_thumbnail!(Val(x), html))
get_platform!(x::Platform, html)::String = try_get(() -> get_platform!(Val(x), html))
get_genre!(x::Platform, html)::String = try_get(() -> get_genre!(Val(x), html))
get_desc!(x::Platform, html)::String = try_get(() -> get_desc!(Val(x), html))

get_name!(::Val{Steam}, html) = html_elements(html, ".apphub_AppName")[1] |> html_text3
get_dev!(::Val{Steam}, html) = html_elements(html, ".dev_row")[1].children[2] |> html_text3
get_publisher!(::Val{Steam}, html) = html_elements(html, ".dev_row")[2].children[2] |> html_text3
get_release_date!(::Val{Steam}, html) = clean_date((html_elements(html, ".date")|>html_text3)[1])
get_thumbnail!(::Val{Steam}, html) = html_attrs(html_elements(html, ".game_header_image_full"), "src")[1]
get_platform!(::Val{Steam}, html) = final_str_platforms(get((html_elements(html, ".sysreq_tabs") |> html_text3), 1, "Windows"))
get_genre!(::Val{Steam}, html) = join(unique(html_elements(html, ["div", ".block_content_inner", "span", "a"]) |> html_text3), ", ")
get_desc!(::Val{Steam}, html) = (d = replace(html_elements(html, ".game_description_snippet")[1] |> html_text3, "\t" => "", ";" => ",")) |> x -> length(x) > 185 ? x[1:183] * "..." : x

function fetch_data!(game::Game)
    html = read_html(game.Steam_Link)

    game.Name = get_name!(Val(Steam), html)
    game.Developer_Names = get_dev!(Val(Steam), html)
    game.Publisher_Names = get_publisher!(Val(Steam), html)
    game.Release_Date = get_release_date!(Val(Steam), html)
    game.Thumbnail = get_thumbnail!(Val(Steam), html)
    game.Platform = get_platform!(Val(Steam), html)
    game.Genre = get_genre!(Val(Steam), html)
    game.Description = get_desc!(Val(Steam), html)
    return game
end

function update_data()
    data = CSV.File("data/curators.csv", delim=", ", stringtype=String)
    listgames::Vector{Game} = []

    @showprogress Threads.@threads for row in data
        country = row[:Country]
        println("Processing: " * country)
        listgames = vcat(listgames, get_games(row[:url], country))
    end

    contributions = CSV.read(IOBuffer(HTTP.get("https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv").body), DataFrame, stringtype=String) |> vals |> df_to_games
    listgames = vcat(listgames, contributions)

    println("Starting massive web scraping")
    @showprogress Threads.@threads for i in eachindex(listgames)
        listgames[i] = listgames[i] |> fetch_data!
    end

    df = listgames |> DataFrame
    sort!(df, :Name)
    for unique_country in unique(df[:, :Country])
        save_data(df[df[:, :Country].==unique_country, :], unique_country)
    end
end

function pre_compile()
    get_games("https://store.steampowered.com/curator/25510407-Games-Devs-from-Denmark/#browse", "Denmark") .|> fetch_data! |> DataFrame
    return nothing
end
