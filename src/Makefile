.PHONY: all

all: pdf

pdf: paper.tex
		latexmk -pdf -recorder -pdflatex="pdflatex -interactive=nonstopmode" -use-make paper.tex

clean:
		rm -fv *.aux *.bbl *.blg *.log *.nav *.out *.snm *.toc *.dvi *.vrb *.bcf *.run.xml *.cut *.lo* *.brf*
			latexmk -c

