TEX = pdflatex
CALC = calc.js

all: $(CALC) report.tex
	if [ ! -d 'data' ];    \
		then mkdir 'data'; \
	fi
	./$(CALC) > data/points.dat
	$(TEX) report.tex
	if [ ! -d 'out' ];    \
		then mkdir 'out'; \
	fi
	mv report.pdf out/report.pdf
	make clean

run:
	if [ ! -r 'out/report.pdf' ];    \
		then echo '\n\nNOTHING TO DISPLAY, BUILD FIRST!'; \
		else open out/report.pdf ;\
	fi

clean:
	rm -fv *.aux *.bbl *.blg *.lof \
	*.out *.pdf *.snm *.vrb *.toc  \
	*.log *.lol *.lot *.nav *.bak  \
	*.loa *.thm
