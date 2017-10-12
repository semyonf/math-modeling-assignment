TEX = pdflatex

all:
	$(TEX) models.tex
	if [ ! -d 'out' ];    \
		then mkdir 'out'; \
	fi
	mv models.pdf out/render.pdf
	make clean

run:
	if [ ! -r 'out/render.pdf' ];    \
		then echo '\n\nNOTHING TO DISPLAY, BUILD FIRST!'; \
		else open out/render.pdf ;\
	fi

clean:
	rm -fv *.aux *.bbl *.blg *.lof \
	*.out *.pdf *.snm *.vrb *.toc  \
	*.log *.lol *.lot *.nav *.bak  \
	*.loa *.thm
