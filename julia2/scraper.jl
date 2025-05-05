include("utils.jl")
include("vals.jl")

function clean_date(date_string::String)
    parts = split(date_string)
    
    # Check if format matches "DD Mon, YYYY" pattern
    if length(parts) == 3 && endswith(parts[2], ",") && all(isdigit, parts[1]) && all(isdigit, parts[3])
        return date_string
    else
        return "To be announced"
    end
end

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

    println("Scraping games list")
    games = Vector{Vector{Game}}(undef, length(data))
    @showprogress Threads.@threads for i in eachindex(data)
        country = data[i][:Country]
        url = data[i][:url]
        try
            games[i] = get_games(url, country)
        catch e
            bt = catch_backtrace()
            @error "Error while fetching games" exception = e url = url
            println("Full backtrace:")
            Base.show_backtrace(stdout, bt)
        end
    end
    listgames = reduce(vcat,games)

    println("Extracting contributions")
    listgames = vcat(listgames, get_contributions())

    # This will bring all of the available data we already have
    # then we cut repetitions, to prevent repetitive scraping.
    listgames = unique(vcat(DataFrame(listgames), get_current_data()), :Steam_Link, keep=:last) |> df_to_games

    println("Starting massive web scraping")
    listgames = scrape_list(listgames)

    save_games(listgames)
end

function update_contributions()
    listgames = unique(vcat(DataFrame(get_contributions()), get_current_data()), :Steam_Link, keep=:last) |> df_to_games
    println("Starting massive web scraping")
    listgames = scrape_list(listgames)
    save_games(listgames)
end