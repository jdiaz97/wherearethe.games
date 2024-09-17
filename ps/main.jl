include("ps.jl")
using DataFrames, CSV, ProgressBars

function p(column::Symbol,df::DataFrame,name::String,func::Function)::String
    value::String = df[i,column]
    if (value == "Unknown")
        return func(name) 
    else
        return value
    end
end

function add_links(file::String)
    df::DataFrame = CSV.read(file, DataFrame; delim = ";;")

    names = df[:,:Name]
    for i in ProgressBar(eachindex(names))
        for (column, func) in [
            (:Epic_Link, get_epic),
            (:Playstation_Link, get_playstation),
            (:Xbox_Link, get_xbox),
            (:Switch_Link, get_switch)
        ] ### what are enums???
            df[i, column] = p(column, df, name, func)
        end
    end
    CSV.write(file,df, delim =";;")
    return nothing
end

path = "export/"
csvs = [
    "Sweden.csv",
    "Switzerland.csv"
]
# global const files::Vector{String} = path*.*(readdir(path)[6:7])
global const files::Vector{String} = path.*csvs 
for file in files
    println(file)
    add_links(file)
end