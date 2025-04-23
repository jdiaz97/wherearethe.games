# WebDriver section
using WebDriver, DataFrames, CSV
@async run(`chromedriver --silent --port=9516 `)
global const wd::RemoteWebDriver = RemoteWebDriver(Capabilities("chrome"), host = "localhost", port = 9516)
current_height!(session::Session) = script!(session, "return document.body.scrollHeight")
scroll_to_bottom!(session::Session) = script!(session, "window.scrollTo(0, document.body.scrollHeight);")

function scroll_and_get_html(url::String)::String
    session::Session = Session(wd) # Will create a new session
    navigate!(session, url)

    last_height = current_height!(session)
    while true
        scroll_to_bottom!(session)
        sleep(3.5)
        new_height = current_height!(session)
        if new_height == last_height
            break;
        end
        last_height = new_height
    end
    text = source(session)
    delete!(session) # important
    return text
end

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

function save_data(df::DataFrame, country::String)
    bits::BitVector = df[:, "Name"] .== "Unknown"
    failed::DataFrame = df[bits, :]
    goods::DataFrame = df[.!bits, :]
    failed = select(failed, :Country, :Steam_Link)
    write_db("export/"*country*".csv", goods)
    write_db("export/failed.csv", failed)
    return nothing
end

function write_db(path::String, df::DataFrame)
    if isfile(path)
        df = unique(vcat(CSV.read(path, DataFrame; delim=";"), df), keep=:last)
    end
    CSV.write(path, df, delim=";")
    return nothing
end