function minify_html(html::String)
    # Replace multiple spaces, newlines, and tabs with a single space
    minified_html = replace(html, r"\s+" => " ")

    # Remove spaces between tags
    minified_html = replace(minified_html, r">\s+<" => "><")

    return minified_html
end
include("geojson.jl")
add_(str) = replace(str, " " => "_")

file = "data/template.html"
include("../.env")

flags = collect(values(country_flags))
countries = collect(keys(country_flags))

for i in eachindex(countries)
    data = read(file,String)
    data = replace(data, "COUNTRY_PLACEHOLDER" => countries[i])
    data = replace(data, "COUNTRY_CODE_PLACEHOLDER" => flags[i])

    path = "countries/"*add_(countries[i])*".html"
    data = minify_html(data)

    open(path, "w") do file
        write(file, data)
    end 
end

