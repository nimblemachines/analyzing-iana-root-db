#!/bin/sh

# Idea: Let's grab snapshots of the IANA root db from the Internet
# Archive's "Wayback machine" at web.archive.org!

# Six month intervals are probably enough - say, end of June and end of
# December. Let's start in 2012 when the latest TLD expansion started.

# The Wayback Machine URLs look like this: 
# https://web.archive.org/web/20210630204655/https://www.iana.org/domains/root/db/

dest=web.archive.org
mkdir -p $dest

for snap in \
    20120622120639 20121230055146 \
    20130630215719 20131231084108 \
    20140703024312 20141231212639 \
    20150627101703 20151223012355 \
    20160703013105 20161227030625 \
    20170629071759 20171228134943 \
    20180702104643 20181231050221 \
    20190702093554 20191231205533 \
    20200629205638 20201231103608 \
    20210630204655
    do
    date=$(echo $snap | sed -E -e 's/(....)(..)(..)....../\1-\2-\3/')
    curl -o $dest/$date.html https://web.archive.org/web/$snap/https://www.iana.org/domains/root/db/
done
