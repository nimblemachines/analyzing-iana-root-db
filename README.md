Curious as to the story with the program for New gTLDs
(https://newgtlds.icann.org/en/) and looking at the DNS root db
(http://www.iana.org/domains/root/db), I noticed something odd and suspicious:
a lot of gTLDs were registered by companies with eerily similiar names: Half
Hallow, LLC; Knob Town, LLC; Steel Falls, LLC.

I finally decided to get to the bottom of the matter, downloaded the HTML
version of the root db, and went at it with Lua, trying to parse out the bits.
I haven't yet written code to download all the domain files (they are also
HTML, and would also need to be scraped), but I did write some simple filters
to show all of Google's, or Donut's registered domains.

That last sentence was kind of a spoiler, I guess. All those weird names
(except for "Beats Electronics, LLC", which matches the pattern) belong to
Donuts, Inc, a Bellevue, WA company that is aggressively adding new TLDs. So
far they have the biggest portfolio of a single company: 201 domains. (241 if
you also count the 40 that have been delegated to United TLD Holdco, which
Donuts now owns.)

I created a parsing mode that blats out the entire database in a form that can
be easily uploaded to Drive as a Sheet. This makes it easy to sort and play
with. And the URLs are finally handled in a nice way (using =HYPERLINK()).

This code is a work in progress! I hope to grab new versions of the root file
and the constituent domain files on a regular basis. Weekly would be great -
these things are changing rapidly!

Running ``./fetch.sh`` will grab the latest root zone db as an HTML file, date
stamp it, and stash it in ``root-db/``.

Running ``./gen.sh`` will read the files in ``root-db/`` and for each one it
finds it will generate two files in ``out/``: a .lua file containing the
database as a table of tables; and a .txt file that is a CSV file suitable for
uploading to Google Docs as a spreadsheet (eg, for further analysis).

``changes.lua`` is a work-in-progress. Since things are changing all the
time - almost daily - I thought it would be nice to make it easy to see what has
changed between two snapshots, but I haven't figured out how to do it yet.

But that's not the whole story.

The IANA root zone database is a moving target. It shows the list of
currently-delegated domains, and who is currently responsible for each one.
But what about the original applications? Is there a list somewhere? It turns
that there used to be, but it's now hard to find. I saw a URL in this gist:

https://gist.github.com/lukaszkorecki/2924179

and decided to try downloading it myself. This is the URL:

http://newgtlds.icann.org/en/program-status/application-results/strings-1200utc-13jun12-en

As of August 2018 that URL redirects to

https://gtldresult.icann.org/application-result/applicationstatus

The page at the original URL was a big HTML table (with .CSV and .PDF download
options); the page at the redirected-to URL shows the first of 56 pages, which
you could presumably download one by one and concatenate.

Fuck that!

Luckily there is a copy of the original table in the Internet Archive's
Wayback Machine. The URL to *that* is

https://web.archive.org/web/20120613142047if_/http://newgtlds-cloudfront.icann.org/sites/default/files/reveal/strings-1200utc-13jun12-en.html

and with that data we can see who the original culprits were...
