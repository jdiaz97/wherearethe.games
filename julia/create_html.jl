file = "data/template.html"
include("../.env")

flags = collect(values(country_flags))
countries = collect(keys(country_flags))

for i in eachindex(countries)
    data = read(file,String)
    data = replace(data, "COUNTRY_PLACEHOLDER" => countries[i])
    data = replace(data, "COUNTRY_CODE_PLACEHOLDER" => flags[i])
    path = "countries/"*countries[i]*".html"

    open(path, "w") do file
        write(file, data)
    end 
end
