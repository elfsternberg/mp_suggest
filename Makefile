FILES = AUTHORS COPYING INSTALL README TODO \
       mp_suggest.hy mp_suggest_man.tex Makefile

TARFILES = ${FILES} mp_suggest_man.html mp_suggest.1 mp_suggest.man

mp_suggest_man.html: mp_suggest_man.tex
	latex2man -H mp_suggest_man.tex mp_suggest_man.html

mp_suggest.1: mp_suggest_man.tex
	latex2man mp_suggest_man.tex mp_suggest.1

mp_suggest.man: mp_suggest.1
	nroff -Tascii -man mp_suggest.1 > mp_suggest.man

all: ${TARFILES}

archive: all
	tar cvf - ${TARFILES} | gzip -9c > mp_suggest.tar.gz
