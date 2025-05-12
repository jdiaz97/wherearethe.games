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