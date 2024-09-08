using TidierVest, Gumbo, Cascadia
using DataFrames, CSV

struct GameInfo
    name::String
    country::String
    description::String
    thumbnail::String
    publisher_names::String
    developer_names::String
    platform::String
    steam_link::String
    release_date::String
    genre::String
end

using Base.Iterators

function extract_platforms(input_string::AbstractString)
    # Define regular expression pattern to match platform names
    regex_pattern = r"Windows|macOS|SteamOS \+ Linux"
    
    # Use eachmatch function to find all occurrences of platform names
    matches = collect(eachmatch(regex_pattern, input_string))
    
    # Extract matched platform names
    platforms = [m.match for m in matches]
    
    return platforms
end

function final_str_platforms(input_string::String)::String
    platforms = extract_platforms(input_string)

    finalstr = ""
    for p in platforms
        finalstr = finalstr*p*", "
    end
    return finalstr[begin:end-2]
end

function get_game_info(url::String,country::String)
    html = read_html(url)

    name = html_elements(html, ".apphub_AppName")[1] |> html_text3
    description = html_elements(html, ".game_description_snippet")[1] |> html_text3
    description = replace(description, "\t" => "")
    developer_names = "Unknown"
    publisher_names = "Unknown"
    try
        developer_names = html_elements(html, ".dev_row")[1].children[2] |> html_text3    
        publisher_names = html_elements(html, ".dev_row")[2].children[2] |> html_text3
    catch
    end
    release_date = (html_elements(html, ".date") |> html_text3)[1]
    thumbnail = html_attrs(html_elements(html, ".game_header_image_full"), "src")[1]
    
    # Hardcoded values
    country = country
    platform = "Windows"
    try
        platform = final_str_platforms((html_elements(html,".sysreq_tabs") |> html_text3)[1])    
    catch
    end

    genre = "Unknown"
    try
        genre= get_genre(html)
    catch
    end
    
    return GameInfo(name, country, description, thumbnail, publisher_names, developer_names, platform, url, release_date,genre)
end
cleanlink(str) = split(str,"?")[1]

function failed_info(url::String,country::String)
    return GameInfo("failed", country, "failed", "failed", "failed", "failed", "failed", url, "failed","failed")
end

# function get_game_info2(file::String, url::String,c::String)
#     html = parsehtml(read(file,String))
    
#     name = html_elements(html, ".apphub_AppName")[1] |> html_text3
#     description = html_elements(html, ".game_description_snippet")[1] |> html_text3
#     description = replace(description, "\t" => "")
#     developer_names = "Unknown"
#     publisher_names = "Unknown"
#     try
#         developer_names = html_elements(html, ".dev_row")[1].children[2] |> html_text3    
#         publisher_names = html_elements(html, ".dev_row")[2].children[2] |> html_text3
#     catch
#     end
#     release_date = (html_elements(html, ".date") |> html_text3)[1]
#     thumbnail = html_attrs(html_elements(html, ".game_header_image_full"), "src")[1]
    
#     # Hardcoded values
#     country = c
#     platform = "Windows"
#     try
#         platform = final_str_platforms((html_elements(html,".sysreq_tabs") |> html_text3)[1])    
#     catch
#     end
#     return GameInfo(name, country, description, thumbnail, publisher_names, developer_names, platform, url, release_date)
# end

function gameinfo_df(a::GameInfo)::DataFrame
    df = DataFrame(
        Name = [a.name],
        Country = [a.country],
        Description = [a.description],
        Thumbnail = [a.thumbnail],
        Publisher_Names = [a.publisher_names],
        Developer_Names = [a.developer_names],
        Platform = [a.platform],
        Steam_Link = [a.steam_link],
        Release_Date = [a.release_date],
        Genre = [a.genre]
    )
    return df
end

"""
This function gets the path of a HTML file that contains a Steam Mentor.
It also gets the name of the country.
"""
function scrape_mentor(path::String,country::String)::DataFrame
    a = parsehtml(read(path,String))
    b = html_elements(a,".recommendation_link") ## all the recomendations of a mentor
    listgames::Vector{String} = html_attrs(b,"href")
    listgames= cleanlink.(listgames)

    data::Vector{GameInfo} = []
    for game in listgames # urls
        try
            push!(data,get_game_info(game,country))    
        catch
            push!(data,failed_info(game,country))
        end
    end

    df::DataFrame = DataFrame()
    for d in data
        df = vcat(df,gameinfo_df(d))
    end

    return df
end

function scrape_mentor2(listgames::Vector{String},country::String)::DataFrame
    
    data::Vector{GameInfo} = []
    for game in listgames
        try
            push!(data,get_game_info(game,country))    
        catch
            println(game)
        end
    end

    df::DataFrame = DataFrame()
    for d in data
        df = vcat(df,gameinfo_df(d))
    end

    return df
end

occursin2(a,b) = occursin(b,a)
cleanlink2(str)::String = split(str,"curator")[1]
function gamelist_from_curatorlist(html::HTMLDocument)::Vector{String}
    b = html_elements(html,"a")
    a = html_elements(b,".Focusable")
    list = html_attrs(a,"href")
    list = list[occursin2.(list,"app")]
    list = cleanlink2.(list)
    return list
end

function save_data(df::DataFrame,country::String)
    if !isdir("export")
        mkdir("export")
    end

    bits = df[:,"Name"] .== "failed"
    failed = df[bits,:]
    goods = df[.!bits,:]

    failed = select(failed, :Country, :Steam_Link)

    country_path = "export/"*country*".csv"
    if isfile(country_path)
        currenty_goods = CSV.read(country_path, DataFrame; delim = ";;")
        goods = vcat(currenty_goods,goods)
        goods = unique(goods)
    else 
        CSV.write(country_path,goods, delim =";;")
    end
    

    export_path = "export/failed.csv"
    if isfile(export_path)
        currenty_failed = CSV.read(export_path, DataFrame; delim = ";;")
        failed = vcat(currenty_failed,failed)
        failed = unique(failed)
    else
        CSV.write(export_path,failed, delim =";;")
    end
    return nothing
end

function get_genre(html)::String
    a = html_elements(html,"div")
    b = html_elements(a,".block_content_inner") 
    c = html_elements(b, ["span","a"]) |> html_text3
    return join(unique(c), ", ")
end
