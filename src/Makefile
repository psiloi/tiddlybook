# makefile to generate example ebook
# copyright 2013-2015 Jean-Pierre Rivière <jn.pierre.riviere (at) gmail.com

# This file is part of TiddlyBook.
#
#    TiddlyBook is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    TiddlyBook is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with TiddlyBook.  If not, see <http://www.gnu.org/licenses/>

.PHONY: clean schemas.makefile links list

ALL: EPUB PDF MOBI EPUB_PNG MOBI_PNG 

# list all targets of this Makefile makefile
list:
	@sh -c "$(MAKE) -p no_targets__ -f $(lastword $(MAKEFILE_LIST)) | awk -F':' '/^[a-zA-Z0-9][^\$$#\/\\t=]*:([^=]|$$)/ {split(\$$1,A,/ /);for(i in A)print A[i]}' | grep -v '__\$$' | sort" 2>/dev/null

# Mostly, for a new project, one has only to adapt
# all the variables below, and not care about the
# remaimining of the makefile.
# Note that there are two possibilities for creating pdf.
# The direct way is not producing good results as of 2014/08/29.
# One has to choose which pdf to make by default.
# Also, the original svg files are in ${SCHEMAS}-inkscape
DOC=../documents
SCHEMAS=../schemas
WIKI_CORENAME=wiki
PROJECT_CORENAME=project
EBOOK_CORENAME=sample
LANGUAGE?=en
WIKI_FILENAME=${WIKI_CORENAME}_${LANGUAGE}
PROJECT_FILENAME=${PROJECT_CORENAME}_${LANGUAGE}
EBOOK_FILENAME=${EBOOK_CORENAME}_${LANGUAGE}
PDF_DIRECT=${DOC}/${EBOOK_FILENAME}-direct.pdf
PDF_CONV=${DOC}/${EBOOK_FILENAME}-conv.pdf
PDF=${PDF_CONV}
EPUB=${DOC}/${EBOOK_FILENAME}.epub
EPUB_PNG=${DOC}/${EBOOK_FILENAME}_png.epub
MOBI=${DOC}/${EBOOK_FILENAME}.mobi
MOBI_PNG=${DOC}/${EBOOK_FILENAME}_png.mobi
WIKI_HTML=${DOC}/${WIKI_FILENAME}.html
PROJECT_RB =${PROJECT_FILENAME}.rb
PROJECT_XML =${PROJECT_FILENAME}.xml
PROJECT_PNG_RB =${PROJECT_FILENAME}_png.rb
PROJECT_PNG_XML =${PROJECT_FILENAME}_png.xml
MAKEFILE_SVG=schemas-svg.makefile
MAKEFILE_PNG=schemas-png.makefile
FIGS=figs
FIGS_SVG=figs-svg
FIGS_PNG=figs-png
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
	  ${PROJECT_CORENAME}*.rb \
	  ${PROJECT_CORENAME}*.xml \
	  ${PROJECT_PNG_RB} ${PROJECT_PNG_XML} \
	  ${MAKEFILE_SVG} \
	  ${MAKEFILE_PNG} \
	  ${SCHEMAS}/${FIGS_SVG} \
	  ${SCHEMAS}/${FIGS_PNG} \
	  ${FIGS_SVG} \
	  ${FIGS_PNG} \
	  schemas_png schemas_svg \
	  ${DOC}/${EBOOK_CORENAME}*.epub \
	  ${DOC}/${EBOOK_CORENAME}*.mobi \
	  ${DOC}/${EBOOK_CORENAME}*.pdf

# generate links for graphics and so that the Makefile shall work.
links:
	@test -e ../documents/figs || ln -s ../schemas/figs-svg ../documents/figs
	@test -e docbook2epub.sh || ln -s ../../../tiddlybook/trunk/src/docbook2epub.sh
	@test -e generate-schemas-makefile.pl || ln -s ../../../tiddlybook/trunk/src/generate-schemas-makefile.pl
	@test -e get-tiddlers.pl || ln -s ../../../tiddlybook/trunk/src/get-tiddlers.pl
	@test -e wiki2docbook.rb || ln -s ../../../tiddlybook/trunk/src/wiki2docbook.rb
	@test -e i18n.rb || ln -s ../../../tiddlybook/trunk/src/i18n.rb
#
${PROJECT_RB} : ${WIKI_HTML}
	./get-tiddlers.pl $< >$@

${PROJECT_XML} : ${PROJECT_RB}
	./wiki2docbook.rb -d $@ -e $< -l ${LANGUAGE}
	jing /usr/share/xml/docbook/schema/rng/5.0/docbook.rng $@
	
${PROJECT_PNG_RB} : ${PROJECT_RB}
	sed -e 's/\.svg\b/.png/g' <$< >$@

${PROJECT_PNG_XML} : ${PROJECT_PNG_RB}
	./wiki2docbook.rb -d $@ -e $< -l ${LANGUAGE}
	jing /usr/share/xml/docbook/schema/rng/5.0/docbook.rng $@
	
check: ${PROJECT_RB}
	./wiki2docbook.rb -c $< -e $< -l ${LANGUAGE}

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

