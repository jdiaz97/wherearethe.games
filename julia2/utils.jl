using WebDriver, DataFrames, CSV, TidierVest, ProgressMeter, HTTP

@enum Platform Steam PlayStation Xbox Switch Epic GOG

# @async run(`chromedriver --silent --port=9516 `)
global const wd::RemoteWebDriver = RemoteWebDriver(Capabilities("chrome"), host = "localhost", port = 9516)
current_height(session::Session) = script!(session, "return document.body.scrollHeight")
scroll_to_bottom(session::Session) = script!(session, "window.scrollTo(0, document.body.scrollHeight);")

function scroll_and_get_html(url::String)::String
    session = Session(wd)
    navigate!(session, url)
    scroll_to_bottom(session); sleep(2); scroll_to_bottom(session); sleep(2);
    
    last_height = current_height(session)
    i = 0
    while true
        scroll_to_bottom(session)
        sleep(4)
        new_height = current_height(session)
        if new_height == last_height
            i = i+1
            if (i>=3)
                break;
            end
        end
        last_height = new_height
    end
    text = source(session)
    delete!(session)
    return text
end

cleanlink(url) = split(url, "?curator")[1] * "/" |> cleanlink2 |> ensure_trailing_slash
cleanlink2(url) = split(url, "/?")[1]
ensure_trailing_slash(str) = endswith(str, "/") ? str : str * "/"

function get_games(url::String, country::String)::Vector{Game}
    html = scroll_and_get_html(url) |> parse_html

    if last(split(url, "/")) == "#browse" # curator
        data = html_elements(html, ".recommendation_link") ## all the recomendations of a mentor
    elseif occursin("list", url) # steam list 
        data = html_elements(html, [".MY9Lke1NKqCw4L796pl4u", ".Focusable", "a"])
    else
        throw("Invalid URL: " * url)
    end

    steam_links::Vector{String} = html_attrs(data, "href") .|> cleanlink |> unique 
    return [Game(Country = country, Steam_Link = link) for link in steam_links]
end

function save_data(df::DataFrame, country)
    bits::BitVector = df[:, :Name] .== "Unknown"
    failed::DataFrame = df[bits, :]
    goods::DataFrame = df[.!bits, :]
    CSV.write("export/"*country*".csv", goods, delim=";")
    CSV.write("export/failed.csv", failed, delim=";")
    return nothing
end

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
    PlayStation_Link::String = "Unknown"
    Xbox_Link::String = "Unknown"
    Switch_Link::String = "Unknown"
    GOG_Link::String = "Unknown"
end

DataFrame(s::Game) = DataFrame([name => [getfield(s, name)] for name in fieldnames(typeof(s))])
DataFrame(games::Vector{Game}) = reduce(vcat, DataFrame.(games))
contr_to_games(df::DataFrame)::Vector{Game} = [Game(Steam_Link = link, Country = Country) for (link, Country) in zip(df[:,:url], df[:,:Country])]
get_contributions()::Vector{Game} = CSV.read(IOBuffer(HTTP.get("https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv").body), DataFrame, stringtype=String) |> vals |> contr_to_games
df_to_games(df::DataFrame)::Vector{Game} = [Game(; Dict(Symbol(name) => row[name] for name in names(df))...) for row in eachrow(df)]
match_current_data(listgames::Vector{Game})::Vector{Game} = unique(vcat(DataFrame(listgames), get_current_data()), [:Country, :Steam_Link], keep=:last) |> df_to_games

function get_current_data()::DataFrame
    df = reduce(vcat,CSV.read.(get_exports(), DataFrame, stringtype = String; delim=";"))
    column = Symbol.(names(df))
    for i in 1:nrow(df)
        for s in column
            if (ismissing(df[i,s]))
                df[i,s] = ""
            end
        end
    end
    return df
end

function get_exports()::Vector{String}
    exp = "export/"
    data = exp.*readdir(exp)
    data = data[data .!= exp*"failed.csv"]
    return data
end

try_get(f,x::String="Unknown") = try f() catch e return x end;

get_name(x::Platform, html)::String = try_get(() -> get_name(Val(x), html))
get_dev(x::Platform, html)::String = try_get(() -> get_dev(Val(x), html))
get_publisher(x::Platform, html)::String = try_get(() -> get_publisher(Val(x), html))
get_release_date(x::Platform, html)::String = try_get(() -> get_release_date(Val(x), html))
get_thumbnail(x::Platform, html)::String = try_get(() -> get_thumbnail(Val(x), html))
get_platform(x::Platform, html)::String = try_get(() -> get_platform(Val(x), html))
get_genre(x::Platform, html)::String = try_get(() -> get_genre(Val(x), html))
get_desc(x::Platform, html)::String = try_get(() -> get_desc(Val(x), html))
    
function scrape_list(listgames::Vector{Game})::Vector{Game}
    @showprogress Threads.@threads for i in eachindex(listgames)
        # If we don't know the date, we scrape it
        if (listgames[i].Release_Date == "To be announced" || listgames[i].Release_Date == "Unknown" )
            listgames[i] = listgames[i] |> fetch_data!
        end
    end
    return listgames
end

function save_games(listgames::Vector{Game})
    df = listgames |> DataFrame
    df = sort(df, :Name)
    
    for unique_country in unique(df[:, :Country])
        save_data(df[df[:, :Country].==unique_country, :], unique_country)
    end
end