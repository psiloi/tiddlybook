#!/bin/bash
# generate epub file from docbook 5 xml file
# copyright 2013-2014 Jean-Pierre Rivière <jn.pierre.riviere (at) gmail.com

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

work() {
  epub=$1
  docbook=$2
  linkname=$3
  schemasdir=${4%/}
  gfxdir=${5%/}
  tmpdir=${6%/}
  case $epub in
    /*) ;;
  *) epub=$PWD/$epub ;;
  esac
  destdir=${epub%/*}
  [[ $destdir == $epub ]] && destdir=.
  echo "epub : $epub"
  echo "docbook : $docbook"
  echo "gfxdir : $gfxdir"
  echo "tmpdir : $tmpdir"
  echo "destdir : $destdir"
  book=$destdir/${docbook%.xml}.epub
  [[ -f $epub ]] && rm -f $epub
  [[ -f $book ]] && rm -f $book
  xmlto -v -o $destdir --skip-validation epub $docbook
  [[ -f $epub ]] || mv $book $epub
  # xmlto is buggy and we have to make a corrections because
  # file 'mimetype' has a line feed character (and thus cannot validate).
  cp $epub /tmp/orig.epub # pour debug
  [[ -d $tmpdir ]] && rm $tmpdir -rf
  unzip -o $epub -d $tmpdir
  echo -n 'application/epub+zip' >$tmpdir/mimetype
  cp -r $schemasdir/$gfxdir $tmpdir/OEBPS
  mv $tmpdir/OEBPS/${gfxdir##*/} $tmpdir/OEBPS/$linkname
  (cd $tmpdir; zip -0 $epub mimetype; zip -r9 $epub META-INF OEBPS)
  rm -rf $tmpdir
}

[[ $# != 5 ]] && echo "use: docbook2epub.sh epub docbook destdir schemasdir gfxdir" && exit 1
work $1 $2 $3 $4 $5 /tmp/epub$$
