using WebDriver, TidierVest
include("utils.jl")

search(session, x::String) = script!(session, "document.getElementById('search_form_input').value = '" * x * "'; document.getElementById('search_form_input').form.submit();")

url(::Val{PlayStation}) = "https://store.playstation.com/en-us/"
url(::Val{Xbox})        = "https://www.xbox.com/en-US/games/store/"
url(::Val{Switch})      = "https://www.nintendo.com/us/store/"
url(::Val{Epic})        = "https://store.epicgames.com/en-US/"
url(::Val{GOG})         = "https://www.gog.com/en/game/"
url(x::Platform) = url(Val(x))

struct Links
    playstation::Vector{String}
    xbox::Vector{String}
    switch::Vector{String}
    epic::Vector{String}
    gog::Vector{String}
end

function search_console(session, console::String, str::String,)
    search(session, console*" "*str)
    sleep(2.5)
    html = source(session) |> parse_html
    res = html_attrs(html_elements(html, [".pAgARfGNTRe_uaK72TAD", "a"]), "href")
    return res[1:3]
end

function search_consoles(session, str::String)
    return Links(
        search_console(session, url(PlayStation), str),
        search_console(session, url(Xbox), str),
        search_console(session, url(Switch), str),
        search_console(session, url(Epic), str),
        search_console(session, url(GOG), str),
    )
end

session::Session = Session(wd)
navigate!(session, "https://duckduckgo.com/?t=h_&q=test&ia=web")

b = search_consoles(session, "Tormented Souls")