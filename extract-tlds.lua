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

-- Replace a few entities and such that are found in the database
function fix_html(s)
    s = s:gsub("&amp;", "&")
    s = s:gsub("&quot;", "'")
    s = s:gsub("&#39;", "'")
    s = s:gsub("&#x200e;", utf8.char(0x200e))
    s = s:gsub("&#x200f;", utf8.char(0x200f))
    return s
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
        f(url, fix_html(domain), domain_type, fix_html(sponsor))
    end
end

-- Aaaaagh! Donuts acquired United TLD Holdco - aka Rightside. So all their
-- domains need to be marked "donuts" too!

-- United TLD Holdco is gone. All of their domains are now Dog Beach, LLC.

-- Just for kicks, keep these sorted.
registries = {
    amazon = "^Amazon Registry",
    donuts = "^%u%l+ %u%l%a+, LLC$",  -- match McCook in 2nd position
    donuts_nopunct = "^%u%l+ %u%l%a+[.,]? LLC$",  -- match McCook in 2nd position
    famousfour = "^dot %u%l+ Limited$",
    godaddy = "^Registry Services, LLC",
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
    ["Registry Services, LLC"] = true,  -- .compare, .select
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

function is_donuts(sponsor)
    return donuts_false_negatives[sponsor] or
        (sponsor:match(registries.donuts) and not
         donuts_false_positives[sponsor])
end

function is_donuts_nopunct(sponsor)
    return donuts_false_negatives[sponsor] or
        sponsor:match(registries.donuts_nopunct) and not
        (donuts_false_positives_nopunct[sponsor] or
         donuts_false_positives[sponsor])
end

iana_root_db_url = "https://www.iana.org/domains/root/db/"

output = {
    lua = {
        prelude = [[
-- Each entry is a table with the following fields: url, domain, domain type, donuts, sponsor
-- The url has had the initial "https://www.iana.org/domains/root/db/" stripped off.
return {]],
        postlude = "}",
        print_entry = function(url, domain, domain_type, annotation, sponsor)
            print(fmt([[  { url = %q, domain = %q, type = %q, donuts = %q, sponsor = %q },]],
                url, domain, domain_type, annotation, sponsor))
        end,
    },
    sheet = {
        prelude = "domain\tdomain type\tdonuts\tsponsor",
        -- No postlude
        print_entry = function(url, domain, domain_type, annotation, sponsor)
            -- Create hyperlinks in a format suitable for Google Docs:
            -- =HYPERLINK("/domains/root/db/azure.html", ".azure")
            print(fmt([[=HYPERLINK("%s","%s")]], iana_root_db_url .. url, domain),
                domain_type, annotation, sponsor)
        end,
    },
    text = {
        -- No prelude or postlude
        print_entry = function(url, domain, domain_type, annotation, sponsor)
            print(fmt("%-20s  %-20s  %-10s  %s",
                domain, domain_type, annotation, sponsor))
        end,
    },
    wiki = {
        -- No prelude or postlude
        print_entry = function(url, domain, domain_type, annotation, sponsor)
            print(fmt("* [[%s %s]]  (%s)\n",
                iana_root_db_url .. url, domain, sponsor))
        end,
    },
}

function maybe_print(s)
    if s then print(s) end
end

function match(dbfile, output_type, which, pattern)
    maybe_print(output[output_type].prelude)

    each_domain(dbfile, function(url, domain, domain_type, sponsor)
        local matched = function()
            if pattern == "donuts" then
                return is_donuts(sponsor)
            elseif pattern == "donuts_nopunct" then
                return is_donuts_nopunct(sponsor)
            else
                -- See if there is a "nickname" in the registries table; if
                -- there is, use that entry as the match pattern; otherwise,
                -- use pattern verbatim.
                return sponsor:match(registries[pattern] or pattern)
            end
        end

        local annotate = function()
            local isdonuts = is_donuts(sponsor)
            local isrightside = sponsor:match(registries.rightside)
            return (isdonuts and "donuts") or
                   (isrightside and "rightside") or ""
        end

        if (which == "match" and matched()) or
            (which == "-match" and not matched()) then
            output[output_type].print_entry(
                url, domain, domain_type, annotate(), sponsor)
        end
    end)

    maybe_print(output[output_type].postlude)
end

if #arg == 4 and arg[3]:match "match" then
    match(arg[1], arg[2], arg[3], arg[4])
elseif #arg == 2 then
    match(arg[1], arg[2], "match", ".")
else
    print [[
Usage: lua extract-tlds.lua <root-db-path> <output_type> [match <pat> | -match <pat>]
           <output_type>  is lua, sheet, text, wiki
           <pat>          is either a registry "nickname" or a Lua pattern;
                          matches the "sponsor" field
]]
end
