include("../scraper.jl")
using HTTP

url = "https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv"
response = HTTP.get(url)
df::DataFrame = CSV.read(IOBuffer(response.body), DataFrame,stringtype=String)

rename!(df, names(df)[2] => "country")
rename!(df, names(df)[3] => "url")

df = unique(df,:url) # remove repetitions

## Checks current .csvs and it will return a new DF without the urls that we already have.
function clean_ifexists(df::DataFrame)::DataFrame
    unique_countries = unique(df[:,:country])
    return_df::DataFrame = DataFrame()
    for unique_country in unique_countries
        path = "export/"*unique_country*".csv"
        available_df = CSV.read(path, DataFrame, stringtype=String; delim = ";;")
        list_urls = available_df[:,:Steam_Link]
        sliced_df = df[df[:,:country] .== unique_country,:]
        bit::BitVector = []
        for i in (1:nrow(sliced_df))
            push!(bit,sliced_df[i,:url] ∉ list_urls)
        end
        return_df = vcat(return_df,sliced_df[bit,:])
    end
    return return_df
end

df = is_game_onlist(df)

function extract_data(df::DataFrame)::DataFrame
    data::Vector{GameInfo} = []
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


df = extract_data(df)