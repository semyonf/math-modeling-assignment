.PHONY: all calc pdf run clean

TEX=pdflatex

FORTRAN=gfortran
CFLAGS=-Wall -Wextra -std=f2008 -fimplicit-none -static-libgfortran -O2

all: pdf

# Все данные для отчёта (data/*.csv, data/results.tex) генерирует программа
calc: program/bin/calc
	mkdir -p data
	./program/bin/calc

program/bin/calc: program/calc.f08
	mkdir -p program/bin
	$(FORTRAN) $(CFLAGS) program/calc.f08 -o program/bin/calc

pdf: calc
	$(TEX) -interaction=nonstopmode -halt-on-error report.tex
	mkdir -p out
	mv report.pdf out/report.pdf
	rm -fv *.aux *.bbl *.blg *.lof \
	*.out *.pdf *.snm *.vrb *.toc  \
	*.log *.lol *.lot *.nav *.bak  \
	*.loa *.thm *.mod

run:
	if [ ! -r 'out/report.pdf' ];    \
		then echo '\n\nNOTHING TO DISPLAY, BUILD FIRST!'; \
		else xdg-open out/report.pdf 2>/dev/null || open out/report.pdf ;\
	fi

clean:
	rm -fv program/bin/* data/*.csv data/*.tex *.mod \
	*.aux *.bbl *.blg *.lof *.out *.pdf *.snm *.vrb \
	*.toc *.log *.lol *.lot *.nav *.bak *.loa *.thm
