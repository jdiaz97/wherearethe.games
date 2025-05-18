include("utils.jl")

tr(x::String) = replace(lowercase(x)," "=> "")

url(::Val{PlayStation}) = "https://store.playstation.com/en-us/"
url(::Val{Xbox}) = "https://www.xbox.com/en-US/games/store/"
url(::Val{Switch}) = "https://www.nintendo.com/us/store/"
url(::Val{Epic}) = "https://store.epicgames.com/en-US/"
url(::Val{GOG}) = "https://www.gog.com/en/game/"
url(x::Platform) = url(Val(x))

function search_console(session, console::String, str::String,)
    script!(session, "document.getElementById('search_form_input').value = '" * console * " " * str * "'; document.getElementById('search_form_input').form.submit();")
    sleep(2)
    html = source(session) |> parse_html
    res = html_attrs(html_elements(html, [".pAgARfGNTRe_uaK72TAD", "a"]), "href")
    return res[1:3]
end

function read_html_epic(session, url)
    navigate!(session, url)
    sleep(1.5)
    return parse_html(source(session))
end

function get_true_link(links::Vector{String}, platform::Platform, name::String, publisher::String)::String
    try
        for link in links
            html = read_html(link)
            new_name = get_name(platform, html)
            new_publisher = get_publisher(platform,html)
            
            validation1::Bool = new_name == name
            validation2::Bool = occursin(tr(new_publisher),tr(publisher)) || occursin2(tr(new_publisher),tr(publisher))
            
            if (validation1 && validation2 && validation3)
                return link
            end
        end
    catch e
    end
    # not a single link succeded, so we guess there's no true link
    return ""
end

get_name(::Val{PlayStation}, html) = html_text3(html_elements(html, [".psw-c-bg-0", "h1"]))[1]
get_publisher(::Val{PlayStation}, html) = html_text3(html_elements(html,[".pdp-game-title","div"]))[4]

get_name(::Val{Xbox}, html) = html_text3(html_elements(html, "h1"))[1]
get_publisher(::Val{Xbox}, html) = html_elements(html,[".ModuleColumn-module__col___StJzB",".typography-module__xdsBody2___RNdGY"])[2] |> html_text3
get_dev(::Val{Xbox}, html) = html_elements(html,[".ModuleColumn-module__col___StJzB",".typography-module__xdsBody2___RNdGY"])[3] |> html_text3

get_name(::Val{Switch}, html) = split(html_text3(html_elements(html, "title")[1]), " for Nintendo")[1]
get_publisher(::Val{Switch}, html) = html_elements(html,[".sc-1237z5p-2.fjIvYK",".TkmhQ"])[findfirst(==(1),(html_elements(html,[".sc-1237z5p-2.fjIvYK","h3"]) |> html_text3) .== "Publisher")] |> html_text3
get_dev(::Val{Switch}, html) = html_elements(html,[".sc-1237z5p-2.fjIvYK",".TkmhQ"])[findfirst(==(1),(html_elements(html,[".sc-1237z5p-2.fjIvYK","h3"]) |> html_text3) .== "Developer")] |> html_text3

get_game(::Val{Epic}, html) = html_text3(html_elements(html, "h1")[1])

get_name(::Val{GOG}, html) = (html_elements(html, ".game-info__title"))[1].children[1].text |> strip
get_dev(::Val{GOG},html) = html_elements(html,[".content-summary-section",".table__row.details__rating.details__row",".details__content.table__row-content","a"])[1] |> html_text3
get_publisher(::Val{GOG},html) = html_elements(html,[".content-summary-section",".table__row.details__rating.details__row",".details__content.table__row-content","a"])[2] |> html_text3

function add_console()
    sessions::Vector{Session} = [Session(wd) for _ in 1:Threads.nthreads()]
    navigate!.(sessions, "https://duckduckgo.com/?t=h_&q=test&ia=web")

    df::DataFrame = get_current_data()
    @showprogress Threads.@threads for unique_country in unique(df[:, :Country])
        temp_df = df[df[:, :Country].==unique_country, :]
        for i in 1:nrow(temp_df)
            name = temp_df[i, :Name]
            publisher = temp_df[i, :Publisher_Names]
            
            platforms = [
                (enum=PlayStation, column=:PlayStation_Link),
                (enum=Xbox, column=:Xbox_Link),
                (enum=Switch, column=:Switch_Link),
                (enum=GOG, column=:GOG_Link)
            ]

            for platform in platforms
                if (temp_df[i, platform.column] == "Unknown")
                    try                    
                    links = search_console(sessions[Threads.threadid()], url(platform.enum), name)
                    temp_df[i, platform.column] = get_true_link(links, platform.enum, name, publisher)
                    catch e 
                    end
                end
            end

            save_data(temp_df, unique_country)
        end
    end
end

html = read_html("https://store.playstation.com/en-us/product/UP4293-PPSA02525_00-TORMENTEDSIEAPS5")
get_publisher(PlayStation,html)