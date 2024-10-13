using HTTP, CSV, DataFrames
include("scraper.jl")
include("vals.jl")

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

function add_contributions()::Nothing
    url = "https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv"
    response = HTTP.get(url)
    df::DataFrame = CSV.read(IOBuffer(response.body), DataFrame,stringtype=String)

    rename!(df, names(df)[2] => "country")
    rename!(df, names(df)[3] => "url")
    
    df = unique(df,:url) # remove repetitions
    df = vals(df) # ;)
    df = clean_ifexists(df) # checks that we don't have it already in the database
    df = clean_ifexists(df;in_failed=true) # checks that we don't have it already in the database

    if nrow(df) > 0
        df = extract_data(df)
        unique_countries::Vector{String} = unique(df[:,:Country])

        for unique_country in unique_countries
            sliced_df::DataFrame = df[df[:,:Country] .== unique_country,:]
            save_data(sliced_df,unique_country)
        end
    else 
        println("No new data")
    end
    return nothing
end
