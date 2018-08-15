-- Figure out what changed between two snapshots of the IANA root db and
-- create a page to explain/point out the changes.

-- Usage: lua changed.lua <db1> <db2>
--   db1 and db2 are Lua files

-- Loading a Lua db file sets the global variable 'db' to the loaded table.

-- Return a table, indexed by domain, representing the Lua file containing
-- a db.
-- Table entries have format: url, domain, domain type, donuts, sponsor
function load(date)
    dofile(date .. "_root-db.lua")
    local d = {}
    for _, ent in ipairs(db) do
        -- index by domain; collect domain type, donuts, and sponsor
        d[ent[2]] = { ent[3], ent[4], ent[5] }
    end
    return d
end

function xxxmain(date1, date2)
    local d1 = load(arg[1])
    local d2 = load(arg[2])

    local changes = {}
    for k1, v1 in pairs(d1) do
        local v2 = d2[k1]
        if not v2 then
            changes[#changes+1] = { "removed", k1, v1 }
        elseif v1[1] ~= v2[1] or v1[2] ~= v2[2] or v1[3] ~= v2[3] then
            changes[#changes+1] = { "changed", k1, v1, v2 }
        end
    end
    for k2, v2 in pairs(d2) do
        if not d1[k2] then
            changes[#changes+1] = { "added  ", k2, v2 }
        end
    end

    for _, k in ipairs(changes) do
        print(k[1], k[2], k[3], k[4])
    end
end


function main(date1, date2)
    old = dofile(date1 .. "_root-db.lua")
    new = dofile(date2 .. "_root-db.lua")

    -- First, let's make it easy to see if a domain exists in the a db. We
    -- make versions that are indexed by domain rather than simply arrays.
    old_domains = {}
    for _,v in ipairs(old) do
        old_domains[v.domain] = v
    end
    new_domains = {}
    for _,v in ipairs(new) do
        new_domains[v.domain] = v
    end
    local changes = {}
    for _,v2 in ipairs(new) do
        if not old_domains[v2.domain] then
            changes[#changes+1] = { "added  ", v2 }
        end
    end
    for _,v1 in ipairs(old) do
        local v2 = new_domains[v1.domain]
        if not v2 then
            changes[#changes+1] = { "removed", v1 }
        elseif v1.type ~= v2.type or v1.donuts ~= v2.donuts or v1.sponsor ~= v2.sponsor then
            changes[#changes+1] = { "changed", v1, v2 }
        end
    end
    for _,c in ipairs(changes) do
        print(c[1], c[2].domain)
    end
end

main(arg[1], arg[2])
