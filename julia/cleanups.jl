## Date Cleanup
# if dates are not specified , we fix them here.

using Dates,CSV,DataFrames
isone(str::String) = length(split(str)) == 1

function clean_dates(value::String)
    is_right_format::Bool = length(split(value)) == 2
    has_comma::Bool = occursin(",",value)

    if(isone(value) || value == "Coming soon" || !is_right_format || !has_comma) 
        return "To be announced"
    else 
        return value
    end
end

p = "export/"
files = p.*readdir(p)
files = files[files .!= "export/failed.csv"]
for file in files
    df = CSV.read(file, DataFrame, types= String, stringtype=String; delim = ";;")
    
    for i in 1:nrow(df)
        
        value = string(df[i,:Release_Date])
        
        if(isone(value) || value == "Coming soon") 
            df[i,:Release_Date] = "To be announced"
        end
    end
    CSV.write(file,df, delim =";;")
end