using CommonMark
include("consoles.jl")
include("contributions.jl")
include("geojson.jl")

function minify_html(html::String)
    # Replace multiple spaces, newlines, and tabs with a single space
    minified_html = replace(html, r"\s+" => " ")

    # Remove spaces between tags
    minified_html = replace(minified_html, r">\s+<" => "><")

    return minified_html
end


add_(str) = replace(str, " " => "_")
addion(str) = replace(str, " " => "-")
macro get_name(x)
    return string(x)
end

function update_countries()
    file = "html/country_template.html"
    include(".env")

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
end

function update_articles()
    template_str = read("html/article_template.html",String)
    folders = [
        "articles/"
        "articulos/"
    ]

    for folder in folders

        og_path = "markdown/"*folder
        exit_path = folder

        mds = readdir(og_path)


        for md in mds
            md_data = read(og_path*md,String)
            meta::String, content::String = split(md_data,";julia")

            eval.(Meta.parse.(split(meta,"\r\n")))


            CONTENT_PLACEHOLDER = split(CommonMark.html(open(Parser(),og_path*md)),";;julia</p>")[2]

            name_html = lowercase(addion(TITLE_PLACEHOLDER))
            URL_PLACEHOLDER = "https://wherearethe.games/"*folder*name_html

            data = template_str
            data = replace(data, "TITLE_PLACEHOLDER" => TITLE_PLACEHOLDER)
            data = replace(data, "URL_PLACEHOLDER" => URL_PLACEHOLDER)
            data = replace(data, "DATE_PLACEHOLDER" => DATE_PLACEHOLDER)
            data = replace(data, "CONTENT_PLACEHOLDER" => CONTENT_PLACEHOLDER)
            data = replace(data, "MAINIMAGE_PLACEHOLDER" => MAINIMAGE_PLACEHOLDER)

            export_path = exit_path*name_html*".html"
            data = minify_html(data)

            open(export_path, "w") do file
                write(file, data)
            end 
        end
    end
end

function update_html()
    update_geojson()
    update_countries()
    update_articles()
end

function update_data()
    df = CSV.File("data/curators.csv", delim =", ", stringtype = String)  |> DataFrame
    for i in 1:nrow(df)
        url = df[i,:url]
        country = df[i,:country]
        try
            create_df(url,country) |> process_df
        catch
            println("Error at")
            println(url)
            println(country)
        end
    end
    
    update_contributions()
end