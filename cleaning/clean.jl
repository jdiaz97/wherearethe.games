using CSV, DataFrames

path = "export/"
files::Vector{String} = path.*["Sweden.csv","Switzerland.csv"]

for file in files
df::DataFrame = CSV.read(file, DataFrame, stringtype=String; delim = ";;")
for i in 1:nrow(df)
    for (platform,str ) in [(:Playstation_Link,", Playstation"),(:Xbox_Link,", Xbox"),(:Switch_Link,", Nintendo")]
        if !(ismissing(df[i,platform] ) || df[i,platform] == "Unknown")
            if !occursin(str,df[i,:Platform]) ## Checks that the str wasn't added before
            df[i,:Platform] = df[i,:Platform]*str
            end
        end 
    end
end
CSV.write(file,df, delim =";;")
end
