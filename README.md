# What:

<code>mp\_suggest</code> is a simple little organizational tool for MP3
collections.  I wrote it a few years ago to help me organize my own
collection, and when the Hy Programming Language came out, I decided it
was time for a minor exercise.  Rewriting <code>mp\_suggest</code> in Hy
was a perfect opportunity.

# Status:

**May 28, 2016** This code is **complete**.  No further work is being
considered.  The TODO file is empty.

# Details:

<code>mp\_suggest</code> does *not* alter your MP3 files; instead, it
prints to stdout a simple <code>bash</code> script that invokes the
command-line program id3v2; you can capture that script and run it by
hand, or pipe the output of <code>mp\_suggest</code> through
<code>sed</code> to make changes on the fly, or just run the output
straight into <code>bash</code> with a unix pipe.

# Notes

Writing <code>mp\_suggest</code> was an interesting exercise in
returning to Lisp after all these years.  I find that I really enjoyed
it (although, honestly, Hy's debugging facilities leave a lot to be
desired).  The style used inside <code>mp\_suggest</code> is most
definitely not Lispy; looking through it, with its persistent use of
cheap anonymous functions and closures and its function-level
metaprogramming, I guess the best language I could compare it to is
Coffeescript.  I like Coffeescript a lot, but I don't get many
opportunities to use it professionally, but the sensibilities of
Coffeescript (especially Reginald Braithwaite's Ristrettology and his
other books on functional programming) heavily influenced the design
decisions I made in <code>mp\_suggest</code>.

# Using:

<code>mp\_suggest</code> comes with a complete list of commands that can
be seen by running the command with no arguments.  See the man page that
comes with it.

# Licensing

This program is released under the terms of the GNU General Public
License (GNU GPL).

You can find a copy of the license in the file COPYING.
