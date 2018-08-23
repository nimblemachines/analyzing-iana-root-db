#!/bin/sh

# We are date-stamping everything now.

# $1 is the date-stamp
function gen() {
    # Run the script to create a Docs sheet of the current db.
    lua extract-tlds.lua root-db/$1.html sheet > out/$1_root-db.txt

    # Run it again to generate a Lua table containing the current db.
    lua extract-tlds.lua root-db/$1.html table > out/$1_root-db.lua
}

mkdir -p out
for snap in root-db/*.html; do gen $(basename $snap .html); done
