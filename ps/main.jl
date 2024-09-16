include("ps.jl")

using DataFrames, CSV

function add_links(file::String)
    df::DataFrame = CSV.read(file, DataFrame; delim = ";;")
    # Initialize columns
    df[:,:Epic_Link] .= ""
    df[:,:Playstation_Link] .= ""
    df[:,:Xbox_Link] .= ""
    df[:,:Switch_link] .= ""

    names = df[:,:Name]
    for i in eachindex(names)
        df[i,:Epic_Link] = get_epic(names[i])
        df[i,:Playstation_Link] = get_playstation(names[i])
        df[i,:Xbox_Link] = get_xbox(names[i])
        df[i,:Switch_link] = get_switch(names[i])
    end
    CSV.write(path,df, delim =";;")
    return nothing
end

path = "export"
files = path*"/".*readdir(path)
for file in files
    println(file)
    add_links(file)
end

