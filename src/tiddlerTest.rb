#!/usr/bin/ruby -Ku
# test suite for tiddler.rb
# coyright 2013-2014 Jean-Pierre Rivière <jn.pierre.riviere (at) gmail.com

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


require_relative 'tiddler'
require "test/unit"

class TestTiddler < Test::Unit::TestCase

  def test_analyze_header
    niveau, titre = Tiddler.analyze_header('===truc ===')
    assert_equal(niveau, 3);
    assert_equal(titre, 'truc');
    niveau, titre = Tiddler.analyze_header('=  simple truc=')
    assert_equal(niveau, 1);
    assert_equal(titre, 'simple truc');
    niveau, titre = Tiddler.analyze_header('== un joli titre ==')
    assert_equal(niveau, 2);
    assert_equal(titre, 'un joli titre');
  end

  def test_analyze_list
    marqueur, item = Tiddler.analyze_list('*un')
    assert_equal(marqueur, '*');
    assert_equal(item, 'un');
    marqueur, item = Tiddler.analyze_list('## deux')
    assert_equal(marqueur, '##');
    assert_equal(item, 'deux');
    marqueur, item = Tiddler.analyze_list('##* trois ou plus ')
    assert_equal(marqueur, '##*');
    assert_equal(item, 'trois ou plus');
    marqueur, item = Tiddler.analyze_list('*### dernier')
    assert_equal(marqueur, '*###');
    assert_equal(item, 'dernier');
  end

  def test_operate_headers
    #{{{
    tiddler = Tiddler.new('simple', [], 'blabla')
    contenu = "= une chose =\ntrès facile"
    trad = "<sect1>\n<title>une chose</title>\ntrès facile\n</sect1>\n"
    assert_equal(trad, tiddler.operate_headers(contenu))
    contenu = "== deux choses ==\nà découvrir\n== deux mystères ==\nà éclaircir"
    trad = "<sect2>\n<title>deux choses</title>\nà découvrir\n</sect2>\n<sect2>\n<title>deux mystères</title>\nà éclaircir\n</sect2>\n"
    assert_equal(trad, tiddler.operate_headers(contenu))
    contenu = "== deux choses ==\nbonnes à dire\n=== précisions ===\nà donner"
    trad = "<sect2>\n<title>deux choses</title>\nbonnes à dire\n<sect3>\n<title>précisions</title>\nà donner\n</sect3>\n</sect2>\n"
    assert_equal(trad, tiddler.operate_headers(contenu))
    contenu = "== deux choses ==\nbonnes à dire\n=== précisions ===\nà donner\n== épilogue ==\n== remerciements =="
    trad = "<sect2>\n<title>deux choses</title>\nbonnes à dire\n<sect3>\n<title>précisions</title>\nà donner\n</sect3>\n</sect2>\n<sect2>\n<title>épilogue</title>\n</sect2>\n<sect2>\n<title>remerciements</title>\n\n</sect2>\n"
    assert_equal(trad, tiddler.operate_headers(contenu))
    contenu = "== membres ==\n=== de droit ===\n==== à vie ====\nAlbert\n== invités ==\nRobert"
    trad = "<sect2>\n<title>membres</title>\n<sect3>\n<title>de droit</title>\n<sect4>\n<title>à vie</title>\nAlbert\n</sect4>\n</sect3>\n</sect2>\n<sect2>\n<title>invités</title>\nRobert\n</sect2>\n"
    assert_equal(trad, tiddler.operate_headers(contenu))
    contenu = "== membres ==\n=== de droit ===\n==== à vie ====\nAlbert\n=== spéciaux ===\nRobert"
    trad = "<sect2>\n<title>membres</title>\n<sect3>\n<title>de droit</title>\n<sect4>\n<title>à vie</title>\nAlbert\n</sect4>\n</sect3>\n<sect3>\n<title>spéciaux</title>\nRobert\n</sect3>\n</sect2>\n"
    assert_equal(trad, tiddler.operate_headers(contenu))
  end #}}}

  def test_operate_lists
    #{{{
    tiddler = Tiddler.new('simple', [], 'blabla')
    contenu = "il y a trois choix :\n#un\n#deux\n#trois"
    trad = "il y a trois choix :\n<orderedlist>\n<listitem>\nun\n</listitem>\n<listitem>\ndeux\n</listitem>\n<listitem>\ntrois\n</listitem>\n</orderedlist>\n"
    assert_equal(trad, tiddler.operate_lists(contenu))
    contenu = "contenu :\n*farine\n*sucre\n*colorants :\n*#E101\n*#\E104"
    trad = "contenu :\n<itemizedlist>\n<listitem>\nfarine\n</listitem>\n<listitem>\nsucre\n</listitem>\n<listitem>\ncolorants :\n<orderedlist>\n<listitem>\nE101\n</listitem>\n<listitem>\nE104\n</listitem>\n</orderedlist>\n</listitem>\n</itemizedlist>\n"
    assert_equal(trad, tiddler.operate_lists(contenu))
    contenu = "contenu :\n*farine\n*sucre\n*colorants :\n*#E101\n*#\E104\n*conservateurs"
    trad = "contenu :\n<itemizedlist>\n<listitem>\nfarine\n</listitem>\n<listitem>\nsucre\n</listitem>\n<listitem>\ncolorants :\n<orderedlist>\n<listitem>\nE101\n</listitem>\n<listitem>\nE104\n</listitem>\n</orderedlist>\n</listitem>\n<listitem>\nconservateurs\n</listitem>\n</itemizedlist>\n"
    assert_equal(trad, tiddler.operate_lists(contenu))
    contenu = "contenu :\n*farine\n*sucre\n*colorants :\n*#artificiels :\n*#*E101\n*#*\E104\n*conservateurs"
    trad = "contenu :\n<itemizedlist>\n<listitem>\nfarine\n</listitem>\n<listitem>\nsucre\n</listitem>\n<listitem>\ncolorants :\n<orderedlist>\n<listitem>\nartificiels :\n<itemizedlist>\n<listitem>\nE101\n</listitem>\n<listitem>\nE104\n</listitem>\n</itemizedlist>\n</listitem>\n</orderedlist>\n</listitem>\n<listitem>\nconservateurs\n</listitem>\n</itemizedlist>\n"
    assert_equal(trad, tiddler.operate_lists(contenu))
  end #}}}

  def test_translate_tables
    tiddler = Tiddler.new('test sur les tableaux', [], 'blabla')
    contenu = "|combat factors|c\n|Subject troop type|Against infantry|Against mounted|h\n|El| 4 | 4 |\n|HCh| 3 | 4 |"
    trad = "{| class=\"wikitable\"\n|+combat factors\n|-\n!Subject troop type\n!Against infantry\n!Against mounted\n|-\n|El\n|align=\"center\"|4\n|align=\"center\"|4\n|-\n|HCh\n|align=\"center\"|3\n|align=\"center\"|4\n|}\n"
    assert_equal(trad, tiddler.translate_tables(contenu))

    contenu = "|simple troops costs|c\n|Troop|>|>|>|>| Reg |h\n|Types| S | O | I | F | X |h\n|Ax| 7|>| 4|>| -- |\n|Wb|~| 5|>|>|>| 3 |"
    trad = "{| class=\"wikitable\"\n|+simple troops costs\n|-\n!Troop\n!align=\"center\" colspan=\"5\"|Reg\n|-\n!Types\n!align=\"center\"|S\n!align=\"center\"|O\n!align=\"center\"|I\n!align=\"center\"|F\n!align=\"center\"|X\n|-\n|Ax\n|align=\"right\" rowspan=\"2\"|7\n|align=\"right\" colspan=\"2\"|4\n|align=\"center\" colspan=\"2\"|--\n|-\n|Wb\n|align=\"right\"|5\n|align=\"center\" colspan=\"4\"|3\n|}\n"
    assert_equal(trad, tiddler.translate_tables(contenu))

    contenu = "|troops costs in AP|c\n|Troop|>|>|>|>| Reg |h\n|~| S | O | I | F | X |h\n|[[Ax]]| 7|>| 4|>| -- |\n|~|--|~|~| 10|--|"
    trad = "{| class=\"wikitable\"\n|+troops costs in AP\n|-\n! rowspan=\"2\"|Troop\n!align=\"center\" colspan=\"5\"|Reg\n|-\n!align=\"center\"|S\n!align=\"center\"|O\n!align=\"center\"|I\n!align=\"center\"|F\n!align=\"center\"|X\n|-\n| rowspan=\"2\"|[[Ax]]\n|align=\"right\"|7\n|align=\"right\" rowspan=\"2\" colspan=\"2\"|4\n|align=\"center\" colspan=\"2\"|--\n|-\n|--\n|align=\"right\"|10\n|--\n|}\n"
    assert_equal(trad, tiddler.translate_tables(contenu))

    contenu = "une ligne.\n\n|tableau simple|c\n|un|deux|\n\n|autre|tableau|h\nun peu réduit"
    trad = "une ligne.\n\n{| class=\"wikitable\"\n|+tableau simple\n|-\n|un\n|deux\n|}\n\n{| class=\"wikitable\"\n!autre\n!tableau\n|}\nun peu réduit"
    assert_equal(trad, tiddler.translate_tables(contenu))
    puts trad
  end

  def test_mediawiki_to_docbook
    tiddler = Tiddler.new('test sur les apostrophes', [], 'blabla')
    contenu = "''A'''s front edge is always first"
    # Mediawiki met l'apostrophe à l'intérieur de l'emphase. Ça se défend : je l'y laisse.
    trad = "<sect2>\n<title>test sur les apostrophes</title>\n<para>\n" <<
      "<emphasis>A'</emphasis>s front edge is always first</para>"
    trad2 = "</sect2>\n"
    puts "=================\ntrad=«#{trad}»\n"
    debut, fin = tiddler.mediawiki_to_docbook(contenu)
    assert_equal(trad, debut)
    assert_equal(trad2, fin)
    contenu = "''A'''s front edge is next to ''B'''s side."
    # Mediawiki normalement se plante sur ce test : il met du gras et le croise avec de l'italique !
    # Mais ce test ne serait pas un problème en wikicreole alors je fais plus intelligemment que mediawiki.
    # le bon codage de base serait ''A''&apos;s front edge is next to ''B''&apos;s side."
    trad = "<sect2>\n<title>test sur les apostrophes</title>\n<para>\n" <<
      "<emphasis>A'</emphasis>s front edge is next to <emphasis>B'</emphasis>" <<
      "s side.</para>"
    debut, fin = tiddler.mediawiki_to_docbook(contenu)
    assert_equal(trad, debut)
    assert_equal(trad2, fin)
    contenu = "two pets:\n*a very ''smart'' cat;\n*a '''big''' dog, ''the cat's dog'' actually."
    trad = "<sect2>\n<title>test sur les apostrophes</title>\n<para>\n" <<
      "two pets:\n<itemizedlist>\n<listitem>\na very <emphasis>smart</emphasis> cat;\n</listitem>\n<listitem>\na <emphasis role=\"strong\">big</emphasis> dog, <emphasis>the cat's dog</emphasis> actually.\n</listitem>\n</itemizedlist>\n</para>"
    debut, fin = tiddler.mediawiki_to_docbook(contenu)
    assert_equal(trad, debut)
    assert_equal(trad2, fin)
  end

  # je ne suis pas sûr de ce test repris d'un vieux test
  def test_docbook
    tableau = WikiTable.new("|combat factors|c\n|Subject troop type|Against infantry|Against mounted|h\n|El|4|4|\n|HCh|3|4|")
    trad = ""
    assert_equal(trad, tableau.docbook)
    tableau = WikiTable.new("|combat factors|c\n|Subject troop type|Against infantry|Against mounted|h\n|El| 4 | 4 |\n|HCh| 3| 4|")
    assert_equal(trad, tableau.docbook)
  end

  def test_operate_tables
    tiddler = Tiddler.new('test sur les tableaux', [], 'blabla')
    contenu = "{| class=\"wikitable\"\n|+tableau simple\n|-\n|un\n|deux\n|}"
    trad = "<table frame=\"all\"><title>tableau simple</title>\n<tgroup cols=\"2\" align=\"left\" rowsep=\"1\">\n<colspec colnum=\"1\" colname=\"c1\"/>\n<colspec colnum=\"2\" colname=\"c2\"/>\n<thead>\n</thead>\n<tbody>\n<row>\n<entry>un</entry><entry>deux</entry>\n</row>\n</tbody>\n</tgroup>\n</table>\n"
    assert_equal(trad, tiddler.operate_tables(contenu))

    contenu = "{| class=\"wikitable\"\n|+combat factors\n|-\n!Subject troop type\n!Against infantry\n!Against mounted\n|-\n|El\n|align=\"center\"|4\n|align=\"center\"|4\n|-\n|HCh\n|align=\"center\"|3\n|align=\"center\"|4\n|}\n"
    trad = "<table frame=\"all\"><title>combat factors</title>\n<tgroup cols=\"3\" align=\"left\" rowsep=\"1\">\n<colspec colnum=\"1\" colname=\"c1\"/>\n<colspec colnum=\"2\" colname=\"c2\"/>\n<colspec colnum=\"3\" colname=\"c3\"/>\n<thead>\n<row>\n<entry>Subject troop type</entry><entry>Against infantry</entry><entry>Against mounted</entry>\n</row>\n</thead>\n<tbody>\n<row>\n<entry>El</entry><entry align=\"center\">4</entry><entry align=\"center\">4</entry>\n</row>\n<row>\n<entry>HCh</entry><entry align=\"center\">3</entry><entry align=\"center\">4</entry>\n</row>\n</tbody>\n</tgroup>\n</table>\n"
    assert_equal(trad, tiddler.operate_tables(contenu))

    contenu = "{| class=\"wikitable\"\n|+simple troops costs\n|-\n!Troop\n!>\n!>\n!>\n!>\n!align=\"center\"|Reg\n|-\n!Types\n!align=\"center\"|S\n!align=\"center\"|O\n!align=\"center\"|I\n!align=\"center\"|F\n!align=\"center\"|X\n|-\n|Ax\n|align=\"right\" rowspan=\"2\"|7\n|>\n|align=\"right\"|4\n|>\n|align=\"center\"|--\n|-\n|Wb\n|align=\"right\"|5\n|>\n|>\n|>\n|align=\"center\"|3\n|}\n"
    trad = "<table frame=\"all\"><title>simple troops costs</title>\n<tgroup cols=\"6\" align=\"left\" rowsep=\"1\">\n<colspec colnum=\"1\" colname=\"c1\"/>\n<colspec colnum=\"2\" colname=\"c2\"/>\n<colspec colnum=\"3\" colname=\"c3\"/>\n<colspec colnum=\"4\" colname=\"c4\"/>\n<colspec colnum=\"5\" colname=\"c5\"/>\n<colspec colnum=\"6\" colname=\"c6\"/>\n<thead>\n<row>\n<entry>Troop</entry><entry>></entry><entry>></entry><entry>></entry><entry>></entry><entry align=\"center\">Reg</entry>\n</row>\n<row>\n<entry>Types</entry><entry align=\"center\">S</entry><entry align=\"center\">O</entry><entry align=\"center\">I</entry><entry align=\"center\">F</entry><entry align=\"center\">X</entry>\n</row>\n</thead>\n<tbody>\n<row>\n<entry>Ax</entry><entry morerows=\"2\" align=\"right\">7</entry><entry>></entry><entry align=\"right\">4</entry><entry>></entry><entry align=\"center\">--</entry>\n</row>\n<row>\n<entry>Wb</entry><entry align=\"right\">5</entry><entry>></entry><entry>></entry><entry>></entry><entry align=\"center\">3</entry>\n</row>\n</tbody>\n</tgroup>\n</table>\n"
    assert_equal(trad, tiddler.operate_tables(contenu))
  end

end
