#!/bin/sh

# We are date-stamping everything now.
stamp=$(date "+%F")

# Fetch a new copy of the IANA root db.
curl -o root-db/${stamp}.html https://www.iana.org/domains/root/db
