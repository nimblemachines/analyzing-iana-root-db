-- Open downloaded root-db.html and extract tlds from it, turning them into
-- a big table, for further analysis.

--[[

An example entry looks like this:

    <tr>
        <td>
            
            <span class="domain tld"><a href="/domains/root/db/academy.html">.academy</a></span></td>
            
        <td>generic</td>
        <td>Half Oaks, LLC</td>
    </tr>

--]]

fmt = string.format

-- Reads a file and returns its contents or ""
function read_file(path)
    local f = io.open(path, "r")
    -- XXX should we return nil instead?
    if not f then return "" end
    local contents = f:read("a")
    f:close()
    return contents
end

function each_domain(dbfile, f)
    local dbhtml = read_file(dbfile)
    for url, domain, domain_type, sponsor in dbhtml:gmatch [[<tr>%s+<td>%s+<span class="domain tld"><a href="/domains/root/db/(..-)">(..-)</a></span></td>%s+<td>(..-)</td>%s+<td>(..-)</td>%s+</tr>]] do
        -- sponsor can contain \n chars - normalize them
        sponsor = sponsor:gsub("\n", ", ")
        -- Because of the sloppiness of the database, in one instance "Dog
        -- Beach, LLC" is really "Dog\tBeach, LLC" and so it screws up the
        -- generation of the spreadsheet - which uses tabs as column
        -- separators. So let's map any tabs to spaces in the sponsor
        -- field.
        sponsor = sponsor:gsub("\t", " ")
        f(url, domain, domain_type, sponsor)
    end
end

-- Replace a few entities and such that are found in the database
function fix_html(s)
    s = s:gsub("&amp;", "&")
    s = s:gsub("&quot;", "'")
    s = s:gsub("&#39;", "'")
    s = s:gsub("&#x200e;", utf8.char(0x200e))
    s = s:gsub("&#x200f;", utf8.char(0x200f))
    return s
end

-- Aaaaagh! Donuts acquired United TLD Holdco - aka Rightside. So all their
-- domains need to be marked "donuts" too!

-- Just for kicks, keep these sorted.
registries = {
    amazon = "^Amazon Registry",
    donuts = "^%u%l+ %u%l%a+, LLC$",  -- match McCook in 2nd position
    donuts_nopunct = "^%u%l+ %u%l%a+[.,]? LLC$",  -- match McCook in 2nd position
    famousfour = "^dot %u%l+ Limited$",
    google = "^Charleston Road Registry",
    microsoft = "^Microsoft",
    rightside = "^United TLD H",
    toplevelholdings = "^Top Level Domain",
    uniregistry = "^Uniregistry",
}

-- If we always check for a comma between the name and "LLC", these are
-- matched as Donuts domains, but they are *not* Donuts domains.
donuts_false_positives = {
    ["Active Network, LLC"] = true,     -- .active
    ["Beats Electronics, LLC"] = true,  -- .beats
}

-- If we allow no punctuation before the "LLC", these are matched as Donuts
-- domains, but they are *not* Donuts domains.
donuts_false_positives_nopunct = {
    ["Plan Bee LLC"] = true,            -- .build
    ["Citadel Domain LLC"] = true,      -- .citadel
    ["Desi Networks LLC"] = true,       -- .desi
    ["Employ Media LLC"] = true,        -- .jobs
    ["Locus Analytics LLC"] = true,     -- .locus
    ["Luxury Partners LLC"] = true,     -- .luxury
    ["Dot Tech LLC"] = true,            -- .tech
    ["Dot Latin LLC"] = true,           -- .uno
    ["Monolith Registry LLC"] = true,   -- .vote
}

-- If we always check for a comma and space between name and "LLC", these
-- are not matched as Donuts domains, but they *are* Donuts domains.
donuts_false_negatives = {
    ["New Falls. LLC"] = true,      -- .catering
    ["Romeo Canyon"] = true,        -- .engineering
    ["Tin Mill LLC"] = true,        -- .irish
    ["Big Hollow,LLC"] = true,      -- .rentals
}

function match(dbfile, matching)
    each_domain(dbfile, function(url, domain, domain_type, sponsor)
        local matched
        if matching == "donuts" then
            matched =
                donuts_false_negatives[sponsor] or
                (sponsor:match(registries.donuts) and not
                 donuts_false_positives[sponsor])
        elseif matching == "donuts_nopunct" then
            matched =
                sponsor:match(registries.donuts_nopunct) and not
                (donuts_false_positives_nopunct[sponsor] or
                 donuts_false_positives[sponsor])
        else
            matched = sponsor:match(registries[matching])
        end
        if matched then
            print(fmt("%-16s  %-10s  %s", domain, domain_type, sponsor))
        end
    end)
end

-- Create hyperlinks in a format suitable for Google Docs:
-- =HYPERLINK("/domains/root/db/azure.html", ".azure")
function gen_sheet(dbfile)
    print("domain\tdomain type\tdonuts\tsponsor")

    each_domain(dbfile, function(url, domain, domain_type, sponsor)
        local isdonuts = donuts_false_negatives[sponsor] or
                         (sponsor:match(registries.donuts) and not
                          donuts_false_positives[sponsor])
        local isrightside = sponsor:match(registries.rightside)
        local donuts = (isdonuts and "donuts") or
                       (isrightside and "rightside") or ""
        url = "https://www.iana.org/domains/root/db/" .. url
        print(fmt([[=HYPERLINK("%s","%s")]], url, fix_html(domain)),
            domain_type, donuts, fix_html(sponsor))
    end)
end

-- Generate a Lua table containing the current root db.
function gen_lua_table(dbfile)
    print "-- Each entry is a table with the following fields: url, domain, domain type, donuts, sponsor"
    print "-- The url has had the initial https://www.iana.org/domains/root/db/ stripped off."
    print "return {"

    each_domain(dbfile, function(url, domain, domain_type, sponsor)
        local isdonuts = donuts_false_negatives[sponsor] or
                         (sponsor:match(registries.donuts) and not
                          donuts_false_positives[sponsor])
        local isrightside = sponsor:match(registries.rightside)
        local donuts = (isdonuts and "donuts") or
                       (isrightside and "rightside") or ""
        print(fmt([[ { url = %q, domain = %q, type = %q, donuts = %q, sponsor = %q },]],
            url, fix_html(domain), domain_type, donuts, fix_html(sponsor)))
    end)
    print "}"
end

if #arg == 3 and arg[2] == "match" then
    match(arg[1], arg[3])
elseif #arg == 2 and arg[2] == "table" then
    gen_lua_table(arg[1])
elseif #arg == 2 and arg[2] == "sheet" then
    gen_sheet(arg[1])
else
    print "Usage: lua extract-tlds.lua <root-db-path> [match <registry> | table | sheet]"
end
