# makefile to generate example ebook
.PHONY: clean schemas.makefile links

ALL: EPUB PDF MOBI EPUB_PNG MOBI_PNG 
	
# Mostly, for a new project, one has only to adapt
# all the variables below, and not care about the
# remaimining of the makefile.
# Note that there are two possibilities for creating pdf.
# The direct way is not producing good results as of 2014/08/29.
# One has to choose which pdf to make by default.
# Also, the original svg files are in ${SCHEMAS}-inkscape
PDF_DIRECT=../documents/sample-direct.pdf
PDF_CONV=../documents/sample-conv.pdf
PDF=${PDF_CONV}
EPUB=../documents/sample.epub
EPUB_PNG=../documents/sample_png.epub
MOBI=../documents/sample.mobi
MOBI_PNG=../documents/sample_png.mobi
PROJECT_HTML=../documents/project.html
PROJECT_RB =project.rb
PROJECT_XML =project.xml
PROJECT_PNG_RB =project_png.rb
PROJECT_PNG_XML =project_png.xml
MAKEFILE_SVG=schemas-svg.makefile
MAKEFILE_PNG=schemas-png.makefile
FIGS=figs
FIGS_SVG=figs-svg
FIGS_PNG=figs-png
DOC=../documents
SCHEMAS=../schemas
SVG_WIDTH=320
PNG_WIDTH=400

EPUB: ${EPUB}

EPUB_PNG: ${EPUB_PNG}
	
MOBI: ${MOBI}

MOBI_PNG: ${MOBI_PNG}

PDF_DIRECT: ${PDF_DIRECT}

PDF_CONV: ${PDF_CONV}

PDF: ${PDF}

clean:
	rm -r 2>/dev/null \
	  ${PROJECT_RB} ${PROJECT_XML} \
	  ${PROJECT_PNG_RB} ${PROJECT_PNG_XML} \
	  ${MAKEFILE_SVG} \
	  ${MAKEFILE_PNG} \
	  ${SCHEMAS}/${FIGS_SVG} \
	  ${SCHEMAS}/${FIGS_PNG} \
	  ${PDF_DIRECT} \
	  ${PDF_CONV} \
	  ${EPUB} \
	  ${EPUB_PNG} \
	  ${MOBI} \
	  ${MOBI_PNG} \
	  ${FIGS_SVG} \
	  ${FIGS_PNG}

# generate links so that the Makefile shall work.
links:
	[ -f docbook2epub.sh ]] || ln -s ../../../tiddlybook/trunk/src/docbook2epub.sh
	[ -f generate-schemas-makefile.pl ]] || ln -s ../../../tiddlybook/trunk/src/generate-schemas-makefile.pl
	[ -f get-tiddlers.pl ]] || ln -s ../../../tiddlybook/trunk/src/get-tiddlers.pl
	[ -f wiki2docbook.rb ]] || ln -s ../../../tiddlybook/trunk/src/wiki2docbook.rb

${PROJECT_RB} : ${PROJECT_HTML}
	./get-tiddlers.pl $< >$@

${PROJECT_XML} : ${PROJECT_RB}
	./wiki2docbook.rb -d $@ $<
	jing /usr/share/xml/docbook/schema/rng/5.0/docbook.rng $@
	
${PROJECT_PNG_RB} : ${PROJECT_RB}
	sed -e 's/\.svg\b/.png/g' <$< >$@

${PROJECT_PNG_XML} : ${PROJECT_PNG_RB}
	./wiki2docbook.rb -d $@ $<
	jing /usr/share/xml/docbook/schema/rng/5.0/docbook.rng $@
	
check: ${PROJECT_RB}
	./wiki2docbook.rb -c $<

schemas_svg: ${MAKEFILE_SVG}
	make -f $<

schemas_png: ${MAKEFILE_PNG}
	make -f $<

${MAKEFILE_SVG} :
	./generate-schemas-makefile.pl svg ${SCHEMAS} ${SVG_WIDTH} $@

${MAKEFILE_PNG} :
	./generate-schemas-makefile.pl png ${SCHEMAS} ${PNG_WIDTH} $@

${EPUB} : ${PROJECT_XML} schemas_svg
	./docbook2epub.sh $@ $< ${FIGS} ${SCHEMAS} ${FIGS_SVG}

${EPUB_PNG} : ${PROJECT_PNG_XML} schemas_png
	./docbook2epub.sh $@ $< ${FIGS} ${SCHEMAS} ${FIGS_PNG}

${MOBI} : ${EPUB}
	ebook-convert $< $@ --enable-heuristics

${MOBI_PNG} : ${EPUB_PNG}
	ebook-convert $< $@ --enable-heuristics

${PDF_DIRECT} : ${PROJECT_XML} schemas_svg
	cd ${DOC}
	xmlto -v --skip-validation --with-fop pdf ../src/$<

${PDF_CONV} : ${EPUB}
	ebook-convert $< $@ --enable-heuristics

