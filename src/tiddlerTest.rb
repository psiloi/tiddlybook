#!/usr/bin/ruby -Ku
# encoding: utf-8
# test suite for tiddler.rb
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


require_relative 'tiddler'
require "test/unit"

class TestTiddler < Test::Unit::TestCase

  def test_analyze_header
    level, title = Tiddler.analyze_header('=== foo  ===')
    assert_equal(level, 3);
    assert_equal(title, 'foo');
    level, title = Tiddler.analyze_header('=  foo bar =')
    assert_equal(level, 1);
    assert_equal(title, 'foo bar');
    level, title = Tiddler.analyze_header('== got a bike ==')
    assert_equal(level, 2);
    assert_equal(title, 'got a bike');
    level, title = Tiddler.analyze_header('====pay attention to spaces====')
    assert_equal(level, 0);
  end

  def test_analyze_list
    marker, item = Tiddler.analyze_list('*one')
    assert_equal(marker, '*');
    assert_equal(item, 'one');
    marker, item = Tiddler.analyze_list('## two')
    assert_equal(marker, '##');
    assert_equal(item, 'two');
    marker, item = Tiddler.analyze_list('##* three or more ')
    assert_equal(marker, '##*');
    assert_equal(item, 'three or more');
    marker, item = Tiddler.analyze_list('*### last')
    # Mediawiki normalement se plante sur ce test : il met du gras et le croise avec de l'italique !
    # Mais ce test ne serait pas un problème en wikicreole alors je fais plus intelligemment que mediawiki.
    # le bon codage de base serait ''A''&apos;s front edge is next to ''B''&apos;s side."
    assert_equal(marker, '*###');
    assert_equal(item, 'last');
  end

  def test_operate_headers
    #{{{
    tiddler = Tiddler.new('simple', [], 'blahblah')
    contents = "= very easy =\nmuch simple"
    trans = "\n</para>\n<section>\n<title>very easy</title>\n<para>\nmuch simple\n</para>\n</section>\n"
    assert_equal(trans, tiddler.operate_headers(contents))
    contents = "== two things ==\nto be done\n== two mysteries ==\nand some fun"
    trans = "\n</para>\n<section>\n<title>two things</title>\n<para>\nto be done\n\n</para></section>\n\n<section>\n<title>two mysteries</title>\n<para>\nand some fun\n</para>\n</section>\n"
    assert_equal(trans, tiddler.operate_headers(contents))
    contents = "== little children ==\ncool cherry cream\n=== rock ===\naround the clock"
    trans = "\n</para>\n<section>\n<title>little children</title>\n<para>\ncool cherry cream\n\n</para>\n<section>\n<title>rock</title>\n<para>\naround the clock\n</para>\n</section>\n\n</section>\n"
    assert_equal(trans, tiddler.operate_headers(contents))
    contents = "== big bang ==\nmost famous scientists\n=== context ===\na quest\n== and... ==\n== thanks =="
    trans = "\n</para>\n<section>\n<title>big bang</title>\n<para>\nmost famous scientists\n\n</para>\n<section>\n<title>context</title>\n<para>\na quest\n\n</para></section>\n</section>\n\n<section>\n<title>and...</title>\n<para>\n\n</para></section>\n\n<section>\n<title>thanks</title>\n<para>\n\n</para>\n</section>\n"
    assert_equal(trans, tiddler.operate_headers(contents))
    contents = "== members ==\n=== by right ===\n==== for life ====\nAlbert\n== guests ==\nRobert"
    trans = "\n</para>\n<section>\n<title>members</title>\n<para>\n\n</para>\n<section>\n<title>by right</title>\n<para>\n\n</para>\n<section>\n<title>for life</title>\n<para>\nAlbert\n\n</para></section>\n</section>\n</section>\n\n<section>\n<title>guests</title>\n<para>\nRobert\n</para>\n</section>\n"
    assert_equal(trans, tiddler.operate_headers(contents))
    contents = "== members ==\n=== by law ===\n==== for life ====\nAlbert\n=== special ===\nRobert"
    trans = "\n</para>\n<section>\n<title>members</title>\n<para>\n\n</para>\n<section>\n<title>by law</title>\n<para>\n\n</para>\n<section>\n<title>for life</title>\n<para>\nAlbert\n\n</para></section>\n</section>\n\n<section>\n<title>special</title>\n<para>\nRobert\n</para>\n</section>\n\n</section>\n"
    assert_equal(trans, tiddler.operate_headers(contents))
  end #}}}

  def test_operate_lists
    #{{{
    tiddler = Tiddler.new('simple', [], 'blahblah')
    contents = "there are three choices:\n#one\n#two\n#three"
    trans = "there are three choices:<orderedlist>\n<listitem>\n<para>\none\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\ntwo\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\nthree\n\n</para>\n</listitem>\n</orderedlist>\n"
    assert_equal(trans, tiddler.operate_lists(contents))
    contents = "old contents :\n*flour\n*sugar\n*dyes:\n*#E101\n*#\E104"
    trans = "old contents :<itemizedlist>\n<listitem>\n<para>\nflour\n</para>\n</listitem>\n"<<
    "<listitem>\n<para>\nsugar\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\ndyes:\n<orderedlist>\n<listitem>\n<para>\nE101\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\nE104\n\n</para>\n</listitem>\n</orderedlist>\n\n</para>\n</listitem>\n</itemizedlist>\n"
    assert_equal(trans, tiddler.operate_lists(contents))
    contents = "contents :\n*flour\n*sugar\n*dyes:\n*#E101\n*#\E104\n*preservative"
    trans = "contents :<itemizedlist>\n<listitem>\n<para>\nflour\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\nsugar\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\ndyes:\n<orderedlist>\n<listitem>\n<para>\nE101\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\nE104\n</para>\n</listitem>\n</orderedlist>\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\npreservative\n\n</para>\n</listitem>\n</itemizedlist>\n"
    assert_equal(trans, tiddler.operate_lists(contents))
    # now testing if French for UTF-8 review
    contents = "ingrédients&nbsp;:\n*blé\n*édulcorant de synthèse\n*colorants&nbsp;:\n*#artificiels&nbsp;:\n" <<
    "*#*E101\n*#*\E104\n*conservateurs (salpêtre)"
    trans = "ingrédients&nbsp;:<itemizedlist>\n<listitem>\n<para>\nblé\n</para>\n</listitem>\n<listitem>\n" <<
    "<para>\nédulcorant de synthèse\n</para>\n</listitem>\n<listitem>\n<para>\ncolorants&nbsp;:\n" <<
    "<orderedlist>\n<listitem>\n<para>\nartificiels&nbsp;:\n<itemizedlist>\n" <<
    "<listitem>\n<para>\nE101\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\nE104\n</para>\n</listitem>\n" <<
    "</itemizedlist>\n</para>\n</listitem>\n</orderedlist>\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\nconservateurs (salpêtre)\n\n</para>\n</listitem>\n</itemizedlist>\n"
    assert_equal(trans, tiddler.operate_lists(contents))
  end #}}}

  def test_translate_tables
    tiddler = Tiddler.new('test on tables', [], 'blahblah')
    contents = "|combat factors|c\n|Subject troop type|Against infantry|Against mounted|h\n|El| 4 | 4 |\n|HCh| 3 | 4 |"
    trans = "{| class=\"wikitable\"\n|+combat factors\n|-\n!Subject troop type\n!Against infantry\n!Against mounted\n" <<
    "|-\n|El\n|align=\"center\"|4\n|align=\"center\"|4\n|-\n|HCh\n|align=\"center\"|3\n|align=\"center\"|4\n|}\n"
    assert_equal(trans, tiddler.translate_tables(contents))

    contents = "|simple troops costs|c\n|Troop|>|>|>|>| Reg |h\n|Types| S | O | I | F | X |h\n|Ax| 7|>| 4|>| -- |\n|Wb|~| 5|>|>|>| 3 |"
    trans = "{| class=\"wikitable\"\n|+simple troops costs\n|-\n!Troop\n!align=\"center\" colspan=\"5\"|Reg\n" <<
    "|-\n!Types\n!align=\"center\"|S\n!align=\"center\"|O\n!align=\"center\"|I\n!align=\"center\"|F\n" <<
    "!align=\"center\"|X\n|-\n|Ax\n|align=\"right\" rowspan=\"2\"|7\n|align=\"right\" colspan=\"2\"|4\n" <<
    "|align=\"center\" colspan=\"2\"|--\n|-\n|Wb\n|align=\"right\"|5\n|align=\"center\" colspan=\"4\"|3\n|}\n"
    assert_equal(trans, tiddler.translate_tables(contents))

    contents = "|troops costs in AP|c\n|Troop|>|>|>|>| Reg |h\n|~| S | O | I | F | X |h\n|[[Ax]]| 7|>| 4|>| -- |\n|~|--|~|~| 10|--|"
    trans = "{| class=\"wikitable\"\n|+troops costs in AP\n|-\n! rowspan=\"2\"|Troop\n" <<
    "!align=\"center\" colspan=\"5\"|Reg\n|-\n!align=\"center\"|S\n!align=\"center\"|O\n" <<
    "!align=\"center\"|I\n!align=\"center\"|F\n!align=\"center\"|X\n|-\n| rowspan=\"2\"|[[Ax]]\n" <<
    "|align=\"right\"|7\n|align=\"right\" rowspan=\"2\" colspan=\"2\"|4\n|align=\"center\" colspan=\"2\"|--\n" <<
    "|-\n|--\n|align=\"right\"|10\n|--\n|}\n"
    assert_equal(trans, tiddler.translate_tables(contents))

    contents = "a line.\n\n|simple table|c\n|one|two|\n\n|other|table|h\na little bit"
    trans = "a line.\n\n{| class=\"wikitable\"\n|+simple table\n|-\n|one\n|two\n|}\n\n" <<
    "{| class=\"wikitable\"\n!other\n!table\n|}\na little bit"
    assert_equal(trans, tiddler.translate_tables(contents))
  end

  def test_tiddlywiki_to_mediawiki
    contents = "a ''big'' cat and a //small// dog in a //''basket''// of ''//yellow//'' straw"
    trans = "a '''big''' cat and a ''small'' dog in a '''''basket''''' of '''''yellow''''' straw"
    tiddler = Tiddler.new('test', [], contents)
    got = tiddler.contents
    assert_equal(trans, got)
  end

  # Caution ! for this test, you supply tiddlywiki and assume it is correctly translated to mediawiki!
  def test_mediawiki_to_docbook
    title = 'test on simple quotes'
    contents = "a ''big'' cat and a //small// dog"
    mediawiki = "a '''big''' cat and a ''small'' dog"
    trans2 = "</section>\n"
    trans = "<section xml:id=\"test_on_simple_quotes\">\n<title>test on simple quotes</title>\n" <<
    "<para>\na <emphasis role=\"strong\">big</emphasis> cat and a <emphasis>small</emphasis> dog\n</para>"
    tiddler = Tiddler.new(title, [], contents)
    tiddlers = { title => tiddler }
    beginning, ending = tiddler.mediawiki_to_docbook(tiddlers)
    assert_equal(mediawiki, tiddler.contents)
    assert_equal(trans, beginning)
    assert_equal(trans2, ending)
    contents = "''A'''s front edge is always first."
    mediawiki = "'''A''''s front edge is always first."
    # mediawiki puts the quote inside emphasis. that has some logic. So let it be like that.
    trans = "<section xml:id=\"test_on_simple_quotes\">\n<title>test on simple quotes</title>\n<para>\n" <<
    "<emphasis role=\"strong\">A</emphasis>'s front edge is always first.\n</para>"
    tiddler = Tiddler.new(title, [], contents)
    tiddlers = { title => tiddler }
    beginning, ending = tiddler.mediawiki_to_docbook(tiddlers)
    assert_equal(mediawiki, tiddler.contents)
    assert_equal(trans, beginning)
    assert_equal(trans2, ending)
    contents = "''A'''s front edge is next to ''B'''s side."
    mediawiki = "'''A''''s front edge is next to '''B''''s side."
    # normally mediawiki fails on this test: it puts grease and cross it with italics!
    # But this test would not be a problemwith wikicreole so we do it brighter than mediawiki.
    # A good base code would be "''A''&apos;s front edge is next to ''B''&apos;s side."
    trans = "<section xml:id=\"test_on_simple_quotes\">\n<title>test on simple quotes</title>\n<para>\n" <<
    "<emphasis role=\"strong\">A</emphasis>'s front edge is next to " <<
    "<emphasis role=\"strong\">B</emphasis>'s side.\n</para>"
    tiddler = Tiddler.new(title, [], contents)
    tiddlers = { title => tiddler }
    beginning, ending = tiddler.mediawiki_to_docbook(tiddlers)
    #puts "=================\ntrans=«#{trans}»(end trans)\n"
    #puts "beginning=#{beginning}"
    #puts "ending=#{ending}"
    assert_equal(mediawiki, tiddler.contents)
    assert_equal(trans, beginning)
    assert_equal(trans2, ending)
    contents = "two pets:\n*a very ''smart'' cat;\n*a '''Rex''' dog, //the cat's dog// actually."
    mediawiki = "two pets:\n*a very '''smart''' cat;\n*a ''''Rex'''' dog, ''the cat's dog'' actually."
    trans = "<section xml:id=\"test_on_simple_quotes\">\n<title>test on simple quotes</title>\n<para>\n" <<
    "two pets:<itemizedlist>\n<listitem>\n<para>\n" <<
    "a very <emphasis role=\"strong\">smart</emphasis> cat;\n</para>\n</listitem>\n" <<
    "<listitem>\n<para>\na '<emphasis role=\"strong\">Rex</emphasis>' dog, " <<
    "<emphasis>the cat's dog</emphasis> actually.\n\n</para>\n</listitem>\n" <<
    "</itemizedlist>\n\n</para>"
    tiddler = Tiddler.new(title, [], contents)
    tiddlers = { title => tiddler }
    beginning, ending = tiddler.mediawiki_to_docbook(tiddlers)
    assert_equal(mediawiki, tiddler.contents)
    assert_equal(trans, beginning)
    assert_equal(trans2, ending)
  end

  def test_operate_tables
    tiddler = Tiddler.new('test on tables', [], 'blahblah')
    contents = "{| class=\"wikitable\"\n|+simple table\n|-\n|one\n|two\n|}"
    trans = "<table frame=\"all\"><title>simple table</title>\n<tgroup cols=\"2\" align=\"left\" rowsep=\"1\">\n" <<
    "<colspec colnum=\"1\" colname=\"c1\"/>\n<colspec colnum=\"2\" colname=\"c2\"/>\n<tbody>\n<row>\n" <<
    "<entry>one</entry><entry>two</entry>\n</row>\n</tbody>\n</tgroup>\n</table>\n"
    assert_equal(trans, tiddler.operate_tables(contents))

    contents = "{| class=\"wikitable\"\n|+combat factors\n|-\n!Subject troop type\n" <<
    "!Against infantry\n!Against mounted\n|-\n|El\n|align=\"center\"|4\n" <<
    "|align=\"center\"|4\n|-\n|HCh\n|align=\"center\"|3\n|align=\"center\"|4\n|}\n"
    trans = "<table frame=\"all\"><title>combat factors</title>\n" <<
    "<tgroup cols=\"3\" align=\"left\" rowsep=\"1\">\n<colspec colnum=\"1\" colname=\"c1\"/>\n" <<
    "<colspec colnum=\"2\" colname=\"c2\"/>\n<colspec colnum=\"3\" colname=\"c3\"/>\n" <<
    "<thead>\n<row>\n<entry>Subject troop type</entry><entry>Against infantry</entry>" <<
    "<entry>Against mounted</entry>\n</row>\n</thead>\n<tbody>\n<row>\n" <<
    "<entry>El</entry><entry align=\"center\">4</entry><entry align=\"center\">4</entry>\n</row>\n" <<
    "<row>\n<entry>HCh</entry><entry align=\"center\">3</entry><entry align=\"center\">4</entry>\n" <<
    "</row>\n</tbody>\n</tgroup>\n</table>\n"
    assert_equal(trans, tiddler.operate_tables(contents))

    contents = "{| class=\"wikitable\"\n|+simple troops costs\n|-\n!Troop\n!>\n!>\n!>\n!>\n" <<
    "!align=\"center\"|Reg\n|-\n!Types\n!align=\"center\"|S\n!align=\"center\"|O\n" <<
    "!align=\"center\"|I\n!align=\"center\"|F\n!align=\"center\"|X\n|-\n|Ax\n" <<
    "|align=\"right\" rowspan=\"2\"|7\n|>\n|align=\"right\"|4\n|>\n|align=\"center\"|--\n|-\n" <<
    "|Wb\n|align=\"right\"|5\n|>\n|>\n|>\n|align=\"center\"|3\n|}\n"
    trans = "<table frame=\"all\"><title>simple troops costs</title>\n" <<
    "<tgroup cols=\"6\" align=\"left\" rowsep=\"1\">\n<colspec colnum=\"1\" colname=\"c1\"/>\n" <<
    "<colspec colnum=\"2\" colname=\"c2\"/>\n<colspec colnum=\"3\" colname=\"c3\"/>\n" <<
    "<colspec colnum=\"4\" colname=\"c4\"/>\n<colspec colnum=\"5\" colname=\"c5\"/>\n" <<
    "<colspec colnum=\"6\" colname=\"c6\"/>\n<thead>\n<row>\n<entry>Troop</entry>" <<
    "<entry>></entry><entry>></entry><entry>></entry><entry>></entry>" <<
    "<entry align=\"center\">Reg</entry>\n</row>\n<row>\n<entry>Types</entry>" <<
    "<entry align=\"center\">S</entry><entry align=\"center\">O</entry>" <<
    "<entry align=\"center\">I</entry><entry align=\"center\">F</entry>" <<
    "<entry align=\"center\">X</entry>\n</row>\n</thead>\n<tbody>\n<row>\n" <<
    "<entry>Ax</entry><entry morerows=\"1\" valign=\"middle\" align=\"right\">7</entry>" <<
    "<entry>></entry><entry align=\"right\">4</entry><entry>></entry>" <<
    "<entry align=\"center\">--</entry>\n</row>\n<row>\n<entry>Wb</entry>" <<
    "<entry align=\"right\">5</entry><entry>></entry><entry>></entry><entry>></entry>" <<
    "<entry align=\"center\">3</entry>\n</row>\n</tbody>\n</tgroup>\n</table>\n"
    assert_equal(trans, tiddler.operate_tables(contents))
  end

end
