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

function each_domain(f)
    local dbhtml = read_file "root-db.html"
    for url, domain, domain_type, sponsor in dbhtml:gmatch [[<tr>%s+<td>%s+<span class="domain tld"><a href="(..-)">(..-)</a></span></td>%s+<td>(..-)</td>%s+<td>(..-)</td>%s+</tr>]] do
        -- sponsor can contain \n chars - normalize them
        sponsor = sponsor:gsub("\n", ", ")
        f(url, domain, domain_type, sponsor)
    end
end

-- Just for kicks, keep these sorted.
registries = {
    amazon = "^Amazon Registry",
    donuts = "^%u%l+ %u%l+, LLC$",
    famousfour = "^dot %u%l+ Limited$",
    google = "^Charleston Road Registry",
    microsoft = "^Microsoft",
    rightside = "^United TLD H",
    toplevelholdings = "^Top Level Domain",
    uniregistry = "^Uniregistry",
}

function match(suspect)
    each_domain(function(url, domain, domain_type, sponsor)
        if sponsor:match(suspect) then
            print(fmt("%-16s  %-10s  %s", domain, domain_type, sponsor))
        end
    end)
end

-- Create hyperlinks in a format suitable for Google Docs:
-- =HYPERLINK("/domains/root/db/azure.html", ".azure")
function export()
    print("domain\tdomain type\tdonuts\tsponsor")

    each_domain(function(url, domain, domain_type, sponsor)
        local isdonuts = sponsor:match(registries.donuts) and not
                         sponsor:match "^Beats Electronics"
        isdonuts = isdonuts and "donuts" or ""
        url = "http://www.iana.org" .. url
        print(fmt([[=HYPERLINK("%s","%s")]], url, domain),
            domain_type, isdonuts, sponsor)
    end)
end

if arg[1] == "match" then
    match(registries[arg[2]])
else
    export()
end
