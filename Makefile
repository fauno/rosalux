default: all

# Todos los articulos en orden
articulos := $(shell echo articulos/*.markdown)

# Todas las opciones que se le pasan a pandoc para crear el libro
# LaTeX: tamaño del libro
pandoc_flags  = -V fontsize=10pt,a5paper,twoside -V documentclass=book
# LaTeX: ubicación de las páginas y márgenes
pandoc_flags += -V geometry=hcentering -V geometry=bindingoffset=1cm
# LaTeX: usar XeLaTeX permite usar fuentes instaladas en el sistema
pandoc_flags += --latex-engine=xelatex
# LaTeX: estilo del libro
pandoc_flags += --include-in-header=layouts/header.tex
pandoc_flags += --include-before-body=layouts/license.tex
# LaTeX: idioma
pandoc_flags += -V lang=spanish
# Bibliografía
pandoc_flags += --csl=apa.csl --bibliography=ref.bib
# Cosas que está bueno tener
pandoc_flags += --smart --table-of-contents

# Crea un solo documento con todos los artículos disponibles.
libro.markdown: $(articulos)
	cat $(articulos) >$@

# Esto es complejo porque hay un bug de pandoc que mantiene el titulo
# del ultimo capitulo en el encabezado de la bibliografía.
#
# Hasta que no se resuelva en lugar de pasar directamente de markdown a
# pdf, hacemos un latex, lo arreglamos y después lo convertimos a pdf.
#
# https://github.com/jgm/pandoc/issues/1632
libro.latex: libro.markdown
	pandoc $(pandoc_flags) -t latex $< \
	| sed "s/\(\\\chapter\*{\)\([^}]\+\)/\1\2\\\markboth{\2}{}/" >$@

# Genera el libro a partir del latex arreglado, usando xelatex que es lo
# que usa internamente pandoc.  La pasada doble es para que pueda saber
# la cantidad de páginas, dónde va la bibliografía y etc.
libro.pdf: libro.latex
	xelatex $<
	xelatex $<

# Genera la imposición de páginas para impresión digital
imposicion.latex: libro.pdf
	pages=$$(pdfinfo $< | grep Pages | cut -d: -f2 | tr -d " ") ;\
	printorder=$$(seq 1 $$pages | sed -e "p" | tr "\n" "," | sed -e "s/,$$//") ;\
	sed -e "s/@@pages@@/$$printorder/g" \
	    -e "s,@@document@@,$<,g" \
	    layouts/binder.latex >$@

imposicion.pdf: imposicion.tex
	pdflatex $<

# Corre todo junto cuando ejecutamos `make`
all: imposicion.pdf

# Limpia el directorio de trabajo
clean:
	rm -fv libro.pdf libro.markdown imposicion.pdf *.aux *.log *.latex *.out *.toc
