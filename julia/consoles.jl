ENV["JULIA_CONDAPKG_BACKEND"] = "Null"
using PythonCall
const duck = PythonCall.pyimport("duckduckgo_search").DDGS
using DataFrames, CSV, ProgressBars

function search_console(name::String,base_url::String)::Dict
    sleep(3)
    success = false
    while !success
        try
            value::Dict = pyconvert(Dict,duck().text(name*" "*base_url,max_results=1)[0])
            success = true
            return value
        catch e
            sleep(2.5)
        end
    end
end

function save_url_if(cond1::Bool,cond2::Bool,data::Dict)::String
    if cond1 && cond2 
        return data["href"]
    else 
        return ""
    end
end

const playstation::String = "https:/store.playstation.com/en-us/product/"
const xbox::String ="https://www.xbox.com/en-US/games/store/"
const switch::String = "https://www.nintendo.com/us/store/products/"
const epic::String = "https://store.epicgames.com/en-US/"
const gog::String = "https://www.gog.com/en/game/"

function get_playstation(game::String)::String
    data = search_console(game, playstation)
    cond1 = (occursin("product",data["href"]) || occursin("concept",data["href"])) && occursin("store.playstation.com",data["href"])
    cond2 = occursin(lowercase(game)*" -",lowercase(data["title"])) || occursin(lowercase(game)*" |",lowercase(data["title"]))
    save_url_if(cond1,cond2,data)
end

function get_xbox(game::String)::String
    data = search_console(game, xbox)
    cond1 = (occursin(lowercase(split(game)[1]),data["href"]) &&  occursin("/games/",data["href"])) && occursin("xbox.com",data["href"])
    cond2 = occursin(lowercase("Buy "*game*" |"),lowercase(data["title"])) || occursin(lowercase(game*" |"),lowercase(data["title"])) 
    save_url_if(cond1,cond2,data)
end

function get_switch(game::String)::String
    data = search_console(game, switch)
    cond1 = occursin("products",data["href"]) && occursin(lowercase(split(game)[1]),data["href"]) && occursin("nintendo.com",data["href"])
    cond2 = occursin(lowercase(game*" - Nintendo"),lowercase(data["title"])) || occursin(lowercase(game*" For Nintendo Switch -"),lowercase(data["title"]))
    save_url_if(cond1,cond2,data)
end

function get_epic(game::String)::String
    data = search_console(game, epic)
    cond1 = occursin("/p/",data["href"]) && occursin(lowercase(split(game)[1]),data["href"]) && occursin("store.epicgames.com",data["href"])
    cond2 = occursin(lowercase(game*" |"),lowercase(data["title"])) 
    save_url_if(cond1,cond2,data)
end

# todo: implement
function get_gog(gamme::String)::String
    data = search_console(game, epic)
    return ""
end

function add_links(file::String)
    df::DataFrame = CSV.read(file, DataFrame, stringtype=String; delim = ";;")

    names::Vector{String} = df[:,:Name]
    for i in ProgressBar(eachindex(names))
        for (column, get_value) in [
            (:Epic_Link, get_epic),
            (:Playstation_Link, get_playstation),
            (:Xbox_Link, get_xbox),
            (:Switch_Link, get_switch)
        ] ### what are enums???
            value = df[i,column]
            if (!ismissing(value))
                if (value == "Unknown")
                    df[i, column] = get_value(names[i]) 
                end
            end
        end
    end
    CSV.write(file,df, delim =";;")
    return nothing
end

function add_consoles(countries::Vector{String})::Nothing
    files::Vector{String} = "export/".*countries.*".csv"

    for file in files
        println("Fetching console links for: "*file)
        add_links(file)
    end
    return nothing
end
