This is a distribution of mp_suggest, an organization tool for MP3
libraries.  It was written primarily as an experiment in learning Hy.
Hy is a lisp-like programming language that runs on top of the Python VM
and exploits Python's access to the running AST in order to build
working Python programs.

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
