## Date Cleanup
# if dates are not specified , we fix them here.

using Dates,CSV,DataFrames
isone(str::String) = length(split(str)) == 1

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