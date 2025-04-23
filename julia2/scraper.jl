using TidierVest
using ProgressMeter
include("utils.jl")

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

# ensure clean results
clean_date(date_string::String) = (date_string == "Coming soon" || !(length(split(date_string)) == 2) || !occursin(",", split(date_string)[2])) ? "To be announced" : date_string
cleanlink(url) = split(url, "/?")[1]*"/"

function final_str_platforms(input_string::String)::String
    platforms = [m.match for m in collect(eachmatch(r"Windows|macOS|SteamOS \+ Linux", input_string))]
    finalstr = ""
    for p in platforms
        finalstr = finalstr * p * ", "
    end
    return finalstr[begin:end-2]
end

safe_extract!(func::Function, game::Game, html, default="Unknown") = try func(game, html) catch _ return default end
get_name!(game::Game, html) = safe_extract!((g,h) -> (g.Name = html_elements(h, ".apphub_AppName")[1] |> html_text3), game, html, "Unknown Game")
get_dev!(game::Game, html) = safe_extract!((g,h) -> (g.Developer_Names = html_elements(h, ".dev_row")[1].children[2] |> html_text3), game, html, "Unknown Developer")
get_publisher!(game::Game, html) = safe_extract!((g,h) -> (g.Publisher_Names = html_elements(h, ".dev_row")[2].children[2] |> html_text3), game, html, "Unknown Publisher")
get_release_date!(game::Game, html) = safe_extract!((g,h) -> (g.Release_Date = clean_date((html_elements(h, ".date")|>html_text3)[1])), game, html, "Unknown Release Date")
get_thumbnail!(game::Game, html) = safe_extract!((g,h) -> (g.Thumbnail = html_attrs(html_elements(h, ".game_header_image_full"), "src")[1]), game, html, "No Thumbnail")
get_platform!(game::Game,html) = (game.Platform = final_str_platforms(get((html_elements(html, ".sysreq_tabs")|>html_text3),1,"Windows")))
get_genre!(game::Game, html) = safe_extract!((g,h) -> (g.Genre = join(unique(html_elements(h, ["div", ".block_content_inner", "span", "a"]) |> html_text3), ", ")), game, html, "No Genre")
get_desc!(game::Game, html) = safe_extract!((g,h) -> (g.Description = (d = replace(html_elements(h, ".game_description_snippet")[1] |> html_text3, "\t" => "", ";" => ",")) |> x -> length(x) > 185 ? x[1:183] * "..." : x), game, html, "No Description")

function fetch_data!(game::Game)
    html = read_html(game.Steam_Link)

    get_name!(game,html)
    get_dev!(game,html)
    get_publisher!(game,html)
    get_desc!(game,html)
    get_genre!(game,html)
    get_release_date!(game,html)
    get_thumbnail!(game,html)
    get_platform!(game,html)
    return game
end

function update_data()
    data = CSV.File("data/curators.csv", delim =", ", stringtype = String)
    Threads.@threads for row in data 
        df = get_games(row[:url],row[:country]) .|> fetch_data! |> DataFrame
        save_data(df, row[:country])
    end
end