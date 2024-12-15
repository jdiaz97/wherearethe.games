using TidierVest
using PyCall
using DataFrames, CSV, ProgressBars
using Base.Iterators

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
    epic_link::String
    playstation_link::String
    xbox_link::String
    switch_link::String
    gog_link::String
end

function broad_in(vec1::Vector,vec2::Vector)
    bit::BitVector = []
    for v in vec1
        push!(bit,v in vec2)
    end
    return bit
end

function clean_date(value::String)
    is_right_format::Bool = length(split(value)) == 2
    has_comma::Bool = occursin(",",value)

    if(value == "Coming soon" || !is_right_format || !has_comma) 
        return "To be announced"
    else 
        return value
    end
end

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

function get_genre(html)::String
    a = html_elements(html,"div")
    b = html_elements(a,".block_content_inner") 
    c::Vector{String} = html_elements(b, ["span","a"]) |> html_text3
    return join(unique(c), ", ")
end

function get_game_info(url::String,country::String)
    html = read_html(url)

    name = html_elements(html, ".apphub_AppName")[1] |> html_text3
    description = html_elements(html, ".game_description_snippet")[1] |> html_text3
    description = replace(description, "\t" => "")
    if length(description) > 185
        description = description[1:185]*"..."
    end
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
    epic_link = "Unknown"
    playstation_link = "Unknown"
    xbox_link = "Unknown"
    switch_link = "Unknown"
    gog_link = "Unknown"
    release_date = clean_date(release_date)
    
    return GameInfo(name, country, description, thumbnail, publisher_names, developer_names, platform, url, release_date,genre,epic_link,playstation_link,xbox_link,switch_link,gog_link)
end
cleanlink(str) = split(str,"?")[1]

function failed_info(url::String,country::String)
    return GameInfo("failed", country, "failed", "failed", "failed", "failed", "failed", url, "failed","failed","failed","failed","failed","failed","failed")
end

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
        Genre = [a.genre],
        Epic_Link = [a.epic_link],
        Playstation_Link = [a.playstation_link],
        Xbox_Link = [a.xbox_link],
        Switch_Link = [a.switch_link]
    )
    return df
end

"""
The most important function
Given a dataframe with 2 columns, :country and :url we will scrape the info from steam. 
Will return a dataframe with the added columns
"""
function extract_data(df::DataFrame)::DataFrame
    data::Vector{GameInfo} = []
    print("New entries are from: ")
    println(unique(df[:,:country]))
    for i in ProgressBar(1:nrow(df)) # urls
        try
            push!(data,get_game_info(df[i,:url],df[i,:country]))    
        catch
            push!(data,failed_info(df[i,:url],df[i,:country]))
        end
    end

    df_final::DataFrame = DataFrame()
        for d::GameInfo in data
            df_final = vcat(df_final,gameinfo_df(d))
        end

    return df_final
end

function save_data(df::DataFrame,country::String)
    if !isdir("export")
        mkdir("export")
    end

    bits ::BitVector= df[:,"Name"] .== "failed"

    failed::DataFrame= df[bits,:]
    goods::DataFrame = df[.!bits,:]

    failed = select(failed, :Country, :Steam_Link)

    country_path = "export/"*country*".csv"
    failed_path = "export/failed.csv"
    write_db(country_path,goods)
    write_db(failed_path,failed)

    return nothing
end

function write_db(path::String,df::DataFrame)
    if isfile(path)
        current = CSV.read(path, DataFrame; delim = ";;")
        df = vcat(current,df)
        df = unique(df, :Steam_Link, keep=:last)
    end
    CSV.write(path,df, delim =";;")
    return nothing
end

## Checks current .csvs and it will return a new DF without the urls that we already have.
function clean_ifexists(df::DataFrame;in_failed::Bool=false)::DataFrame
    unique_countries::Vector{String} = unique(df[:,:country])
    return_df::DataFrame = DataFrame()
    for unique_country in unique_countries
        if in_failed
            path = "export/failed.csv"
        else
            path = "export/"*unique_country*".csv"
        end
        sliced_df::DataFrame = df[df[:,:country] .== unique_country,:]
        if (isfile(path))
            available_df = CSV.read(path, DataFrame, stringtype=String; delim = ";;")
            list_urls::Vector{String} = available_df[:,:Steam_Link]
            bit::BitVector = []
            for i in (1:nrow(sliced_df))
                push!(bit,sliced_df[i,:url] ∉ list_urls)
            end
            return_df = vcat(return_df,sliced_df[bit,:])
        else 
            create_empty_csv(path)
            return_df = vcat(return_df,sliced_df)
        end
    end
    return return_df
end

function create_empty_csv(path::String)
    columns = [
    "Name", "Country", "Description", "Thumbnail", "Publisher_Names",
    "Developer_Names", "Platform", "Steam_Link", "Release_Date", "Genre",
    "Epic_Link", "Playstation_Link", "Xbox_Link", "Switch_Link"
    ]

    df = DataFrame([[] for _ in columns], columns)
    CSV.write(path, df, delim=";;")
    return nothing
end

PyCall.py"""
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.webdriver.common.keys import Keys
import time

def scroll_and_get_html(url):
    # Set up the webdriver (you'll need to specify the path to your webdriver)
    driver = webdriver.Chrome()
    
    # Open the website
    driver.get(url)
    
    # Get the initial height of the page
    last_height = driver.execute_script("return document.body.scrollHeight")
    
    while True:
        # Scroll to the bottom of the page
        driver.execute_script("window.scrollTo(0, document.body.scrollHeight);")
        
        # Wait for the page to load
        time.sleep(2)
        
        # Calculate new scroll height and compare with last scroll height
        new_height = driver.execute_script("return document.body.scrollHeight")
        if new_height == last_height:
            break
        last_height = new_height
    
    # Get the page source (HTML)
    html = driver.page_source
    
    # Close the browser
    driver.quit()
    
    return html
"""

scroll_and_get_html(str) = py"scroll_and_get_html"(str)
chopchop(data) = split(data,"?curator")[1]

function check_slash(str)
    if last(str) == '/'
        return str 
    else 
        str*"/"
    end
end

## list
function create_df1(url::String,country::String)::DataFrame
    html = scroll_and_get_html(url) |> parse_html
    d = html_elements(html,[".MY9Lke1NKqCw4L796pl4u",".Focusable","a"])
    data::Vector{String} = html_attrs(d,"href") |> unique .|> chopchop .|> check_slash
    return DataFrame(country = country, url = data)
end

## #browse
function create_df2(url::String,country::String,get_desc::Bool=false)::DataFrame
    html = scroll_and_get_html(url) |> parse_html
    b = html_elements(html,".recommendation_link") ## all the recomendations of a mentor
    listgames::Vector{String} = html_attrs(b,"href") .|> cleanlink |> unique .|> check_slash
    description = html_elements(html,".recommendation_desc")
    if get_desc
        return DataFrame(url = listgames, country = country,description=description)
    else
        return DataFrame(url = listgames, country = country)
    end
end

function create_df(url::String,country::String,get_desc::Bool=false)::DataFrame
    is_curator = last(split(url,"/")) == "#browse"
    is_list = occursin("list",url) 
    
    if is_curator
        return create_df2(url,country,get_desc)
    elseif is_list
        return create_df1(url,country)
    else 
        throw("Invalid URL: "*url)
    end
end

function process_df(dataframe::DataFrame)
    dataframe = unique(dataframe,:url) # remove repetitions
    dataframe = clean_ifexists(dataframe) # checks that we don't have it already in the database
    dataframe = clean_ifexists(dataframe;in_failed=true) # checks that we don't have it already in the database
    
    if nrow(dataframe) > 0
        dataframe = extract_data(dataframe)
        unique_countries::Vector{String} = unique(dataframe[:,:Country])

        for unique_country in unique_countries
            sliced_dataframe::DataFrame = dataframe[dataframe[:,:Country] .== unique_country,:]
            save_data(sliced_dataframe,unique_country)
        end
    else 
        println("No new data")
    end
    return nothing
end
