using HTTP, CSV, DataFrames

url = "https://docs.google.com/spreadsheets/d/1zALLUvzvaVkqnh0d74CeBYKe1XjBpT0wCMyIGpQhi0A/export?format=csv"
response = HTTP.get(url)
data::DataFrame = CSV.read(IOBuffer(response.body), DataFrame)

names(data)[2] = "country"
rename!(data, "Country of development" => "country")
rename!(data, names(data)[3] => "Steam_Link")
