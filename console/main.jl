include("ps.jl")
using DataFrames, CSV, ProgressBars

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

path = "export/"
csvs = [
    "Poland.csv",
    "Canada.csv"
]
# global const files::Vector{String} = path*.*(readdir(path)[6:7])
global const files::Vector{String} = path.*csvs 

for file in files
    println(file)
    add_links(file)
end