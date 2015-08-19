default: all

articulos := $(shell echo articulos/*.markdown)

# Todas las opciones que se le pasan a pandoc
pandoc_flags  = -V fontsize=10pt,a5paper,twoside -V documentclass=book
pandoc_flags += -V geometry=hcentering -V geometry=bindingoffset=1cm
pandoc_flags += --latex-engine=xelatex --table-of-contents
pandoc_flags += --include-in-header=layouts/header.tex
pandoc_flags += --include-before-body=layouts/license.tex
pandoc_flags += --csl=apa.csl --bibliography=ref.bib --smart
pandoc_flags += --email-obfuscation=references -V lang=spanish

# Crea un solo documento con todos los artículos disponibles.
libro.markdown: $(articulos)
	cat $(articulos) >$@

# https://github.com/jgm/pandoc/issues/1632
libro.latex: libro.markdown
	pandoc $(pandoc_flags) -t latex $< \
	| sed "s/\(\\\chapter\*{\)\([^}]\+\)/\1\2\\\markboth{\2}{}/" >$@

libro.pdf: libro.latex
	xelatex $<
	xelatex $<

imposicion.latex: libro.pdf
	pages=$$(pdfinfo $< | grep Pages | cut -d: -f2 | tr -d " ") ;\
	printorder=$$(seq 1 $$pages | sed -e "p" | tr "\n" "," | sed -e "s/,$$//") ;\
	sed -e "s/@@pages@@/$$printorder/g" \
	    -e "s,@@document@@,$<,g" \
	    layouts/binder.latex >$@

imposicion.pdf: imposicion.tex
	pdflatex $<

all: imposicion.pdf

clean:
	rm -fv libro.pdf libro.markdown imposicion.pdf *.aux *.log *.latex *.out *.toc
