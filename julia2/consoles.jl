using WebDriver, TidierVest

search(session, x::String) = script!(session, "document.getElementById('search_form_input').value = '" * x * "'; document.getElementById('search_form_input').form.submit();")
const global playstation::String = "https:/store.playstation.com/en-us/ "
const global xbox::String = "https://www.xbox.com/en-US/games/store/ "
const global switch::String = "https://www.nintendo.com/us/store/ "
const global epic::String = "https://store.epicgames.com/en-US/ "
const global gog::String = "https://www.gog.com/en/game/ "
const global wd::RemoteWebDriver = RemoteWebDriver(Capabilities("chrome"), host="localhost", port=9516)

struct Links
    playstation::Vector{String}
    xbox::Vector{String}
    switch::Vector{String}
    epic::Vector{String}
    gog::Vector{String}
end

function search_console(session, console::String, str::String,)
    search(session, console * str)
    sleep(2.5)
    html = source(session) |> parse_html
    res = html_attrs(html_elements(html, [".pAgARfGNTRe_uaK72TAD", "a"]), "href")
    return res[1:3]
end

function search_consoles(session, str::String)
    return Links(
        search_console(session, playstation, str),
        search_console(session, xbox, str),
        search_console(session, switch, str),
        search_console(session, epic, str),
        search_console(session, gog, str),
    )
end

session::Session = Session(wd)
navigate!(session, "https://duckduckgo.com/?t=h_&q=test&ia=web")

b = search_consoles(session, "Tormented Souls")