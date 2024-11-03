using HTTP, CSV, DataFrames
include("scraper.jl")
include("scraper2.jl")
include("vals.jl")

function update_contributions()::Nothing
    url = "https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv"
    response = HTTP.get(url)
    df::DataFrame = CSV.read(IOBuffer(response.body), DataFrame,stringtype=String)

    rename!(df, names(df)[2] => "country")
    rename!(df, names(df)[3] => "url")
    df = vals(df) # ;)
    
    process_df(df)
end