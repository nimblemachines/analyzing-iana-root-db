#!/bin/sh

# We are date-stamping everything now.
stamp=$(date "+%F")

# Run the script to create a Docs sheet of the current db.
lua extract-tlds.lua ${stamp}_root-db.html sheet > ${stamp}_root-db.txt

# Run it again to generate a Lua table containing the current db.
lua extract-tlds.lua ${stamp}_root-db.html table > ${stamp}_root-db.lua
