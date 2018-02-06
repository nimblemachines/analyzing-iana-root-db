Curious as to the story with the program for New gTLDs
(https://newgtlds.icann.org/en/) and looking at the DNS root db
(http://www.iana.org/domains/root/db), I noticed something odd and suspicious:
a lot of gTLDs were registered by companies with eerily similiar names: Half
Hollow, LLC; Knob Town, LLC; Steel Falls, LLC.

I finally decided to get to the bottom of the matter, downloaded the HTML
version of the root db, and went at it with Lua, trying to parse out the bits.
I haven't yet written code to download all the domain files (they are also
HTML, and would also need to be scraped), but I did write some simple filters
to show all of Google's, or Donut's registered domains.

That last sentence was kindof a spoiler, I guess. All those weird names
(except for "Beats Electronics, LLC", which matches the pattern) belong to
Donuts, Inc, a Bellevue, WA company that is aggressively adding new TLDs. So
far they have the biggest portfolio of a single company: 190 domains.

I created a parsing mode that blats out the entire database in a form that can
be easily uploaded to Drive as a Sheet. This makes it easy to sort and play
with. And the URLs are finally handled in a nice way (using =HYPERLINK()).

This code is a work in progress! I hope to grab new versions of the root file
and the constituent domain files on a regular basis. Weekly would be great -
these things are changing rapidly right now!

Is there a simple shell script in the works to be run by cron? We'll see.
