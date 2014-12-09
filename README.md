<code>mp_suggest</code> is a simple little organizational tool for MP3
collections.  I wrote it a few years ago to help me organize my own
collection, and when the Hy Programming Language came out, I decided it
was time for a minor exercise.  Rewriting mp\_suggest in Hy was a
perfect opportunity.

<code>mp\_suggest</code> does *not* alter your MP3 files; instead, it
prints to stdout a simple Bash script that invokes the command-line
program id3v2; you can capture that script and run it by hand, or pipe
the output of <code>mp\_suggest</code> through <code>sed</code> to make
changes on the fly, or just run the output straight into Bash with a
unix pipe.

Writing mp_suggest was an interesting exercise in returning to Lisp
after all these years.  I find that I really enjoyed it (although,
honestly, Hy's debugging facilities leave a lot to be desired).  The
style used inside mp_suggest is most definitely not Lispy; looking
through it, with its persistent use of cheap anonymous functions and
closures and its function-level metaprogramming, I guess the best
language I could compare it to is Coffeescript.  I like Coffeescript a
lot, but I don't get many opportunities to use it professionally, but
the sensibilities of Coffeescript (especially Reginald Braithwaite's
Ristrettology and his other books on functional programming) heavily
influenced the design decisions I made in mp_suggest.

* Licensing

  This program is released under the terms of the GNU General Public
  License (GNU GPL).

  You can find a copy of the license in the file COPYING.

* Using:

  mp_suggest comes with a complete list of commands that can be seen by
  running the command with no arguments.  See the man page that comes
  with it.

* To do:

  The TODO file is empty for a reason. This was mostly an exercise in 
  writing Hy.
