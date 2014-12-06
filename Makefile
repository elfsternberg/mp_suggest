FILES = AUTHORS COPYING INSTALL README TODO \
       mp_suggest.hy mp_suggest_man.tex Makefile

TARFILES = ${FILES} mp_suggest_man.html mp_suggest.1 mp_suggest.man

mp_suggest_man.html: mp_suggest_man.tex
	latex2man -H $< $@

mp_suggest.1: mp_suggest_man.tex
	latex2man $< $@

mp_suggest.man: mp_suggest.1
	nroff -Tascii -man $< > $@

mp_suggest_man.pdf: mp_suggest_man.tex
	xelatex $<

clean:
	rm mp_suggest.man mp_suggest.1 mp_suggest_man.log mp_suggest_man.out mp_suggest_man.aux mp_suggest_man.pdf

all: ${TARFILES}

archive: all
	tar cvf - ${TARFILES} | gzip -9c > mp_suggest.tar.gz
