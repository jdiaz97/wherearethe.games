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
    bits::BitVector = df[:, "Name"] .== "Unknown"
    failed::DataFrame = df[bits, :]
    goods::DataFrame = df[.!bits, :]
    failed = select(failed, :Country, :Steam_Link)
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

df_to_games(df::DataFrame)::Vector{Game} = [Game(Steam_Link = link, Country = country) for (link, country) in zip(df[:,:url], df[:,:Country])]

function get_current_data()::DataFrame
    df = reduce(vcat,CSV.read.(get_exports(), DataFrame, stringtype = String; delim=";"))
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
    