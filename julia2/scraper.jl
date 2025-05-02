include("utils.jl")
include("vals.jl")

clean_date(date_string::String) = (date_string == "Coming soon" || (length(split(date_string)) == 2) || !occursin(",", split(date_string)[2])) ? "To be announced" : date_string
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

get_name(::Val{Steam}, html) = html_elements(html, ".apphub_AppName")[1] |> html_text3
get_dev(::Val{Steam}, html) = html_elements(html, ".dev_row")[1].children[2] |> html_text3
get_publisher(::Val{Steam}, html) = html_elements(html, ".dev_row")[2].children[2] |> html_text3
get_release_date(::Val{Steam}, html) = clean_date((html_elements(html, ".date")|>html_text3)[1])
get_thumbnail(::Val{Steam}, html) = html_attrs(html_elements(html, ".game_header_image_full"), "src")[1]
get_platform(::Val{Steam}, html) = final_str_platforms(get((html_elements(html, ".sysreq_tabs") |> html_text3), 1, "Windows"))
get_genre(::Val{Steam}, html) = join(unique(html_elements(html, ["div", ".block_content_inner", "span", "a"]) |> html_text3), ", ")
get_desc(::Val{Steam}, html) = (d = replace(html_elements(html, ".game_description_snippet")[1] |> html_text3, "\t" => "", ";" => ",")) |> x -> length(x) > 185 ? x[1:183] * "..." : x

function fetch_data!(game::Game)
    html = read_html(game.Steam_Link)

    game.Name = get_name(Steam, html)
    game.Developer_Names = get_dev(Steam, html)
    game.Publisher_Names = get_publisher(Steam, html)
    game.Release_Date = get_release_date(Steam, html)
    game.Thumbnail = get_thumbnail(Steam, html)
    game.Platform = get_platform(Steam, html)
    game.Genre = get_genre(Steam, html)
    game.Description = get_desc(Steam, html)
    return game
end

function update_data()
    data = CSV.File("data/curators.csv", delim=", ", stringtype=String)
    listgames::Vector{Game} = []
    sessions = [Session(wd) for _ in 1:Threads.nthreads()]
    sleep(1.5)

    println("Scraping games list")
    @showprogress Threads.@threads for row in data
        country = row[:Country]
        listgames = vcat(listgames, get_games(sessions[Threads.threaid()], row[:url], country))
    end
    delete.(sessions)

    println("Extracting contributions")
    contributions = CSV.read(IOBuffer(HTTP.get("https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv").body), DataFrame, stringtype=String) |> vals |> df_to_games
    listgames = vcat(listgames, contributions)

    # This will bring all of the available data we already have
    # then we cut repetitions, to prevent repetitive scraping.
    listgames = unique(vcat(DataFrame(listgames), get_current_date(listgames)), :Steam_Link, keep=:last) |> df_to_games

    println("Starting massive web scraping")
    @showprogress Threads.@threads for i in eachindex(listgames)
        # If we know the date, we won+t scrape the pages again
        if (listgames[i].Release_Date == "To be announced" && listgames[i].Release_Date == "Unknown" )
            listgames[i] = listgames[i] |> fetch_data!
        end
    end

    df = listgames |> DataFrame
    sort(df, :Name)
    for unique_country in unique(df[:, :Country])
        save_data(df[df[:, :Country].==unique_country, :], unique_country)
    end
end
