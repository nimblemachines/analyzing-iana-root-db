#!/bin/sh

# We are date-stamping everything now.

# If $1 defined, use it as the stamp; otherwise, use today's date.
if [ $1 ]; then
   stamp=$1
else
   stamp=$(date "+%F")
fi

echo Generating for $stamp

# Run the script to create a Docs sheet of the current db.
lua extract-tlds.lua ${stamp}_root-db.html sheet > ${stamp}_root-db.txt

# Run it again to generate a Lua table containing the current db.
lua extract-tlds.lua ${stamp}_root-db.html table > ${stamp}_root-db.lua
