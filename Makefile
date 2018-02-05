.PHONY:calc pdf clean

TEX=pdflatex

FORTRAN=gfortran
CFLAGS=-Wall -std=f2008ts -fimplicit-none -ftree-vectorizer-verbose=2 \
-Wno-maybe-uninitialized -static-libgfortran -flto

all:calc
# all:calc pdf

calc: program/bin/calc
	if [ ! -d 'data' ]; then mkdir 'data'; fi
	./program/bin/calc

program/bin/calc: program/calc.f08
	if [ ! -d 'program/bin' ]; then mkdir 'program/bin'; fi
	$(FORTRAN) $(CFLAGS) program/calc.f08 -o program/bin/calc

pdf:
	$(TEX) report.tex
	if [ ! -d 'out' ]; then mkdir 'out'; fi
	mv report.pdf out/report.pdf
	rm -fv *.aux *.bbl *.blg *.lof \
	*.out *.pdf *.snm *.vrb *.toc  \
	*.log *.lol *.lot *.nav *.bak  \
	*.loa *.thm

run:
	if [ ! -r 'out/report.pdf' ];    \
		then echo '\n\nNOTHING TO DISPLAY, BUILD FIRST!'; \
		else open out/report.pdf ;\
	fi

clean:
	rm -fv program/bin/* program/obj/*;