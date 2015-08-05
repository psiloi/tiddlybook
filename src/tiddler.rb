# transcript mediawiki into docbook
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


# classes for the analyze and translation into mediawiki of tiddlywiki tables

class TiddlyCell
  attr_reader :contents
  attr_reader :colspan
  attr_reader :rowspan
  attr_reader :align

  def initialize(contents, colspan = 0, rowspan = 0)
    @contents = contents.strip
    @colspan = colspan
    @rowspan = rowspan
    @align = ''
    if contents != ''
      if contents[0] == ' '
	@align = (contents[-1] == ' ') ? 'center' : 'right'
      elsif contents[-1] == ' '
	@align = 'left'
      end
    end
    #puts "initialize(\"#{contents}\", #{colspan}, #{rowspan}) : #{to_s}"
  end

  def inc_rowspan
    @rowspan = 1 if @rowspan == 0
    @rowspan += 1
  end

  def to_s
    "(\"#{@contents}\" colspan=#{@colspan} rowspan=#{@rowspan})"
  end

  # translate the cell into mediawiki (one cell for each line).
  #
  # @param beg String : "|" or "!" according to the context of the table
  # @return String : "" or a complete line, with eventual style included
  #
  # supports rowspan, colspan, align.
  def to_mediawiki(beg)
    trans = ''
    unless @rowspan == 1
      rowspan = ''
      multiline =  @rowspan != 0
      aligned = @align != ''
      rowspan = "rowspan=\"#{@rowspan}\"" if multiline
      align = (aligned) ? "align=\"#{@align}\"" : ''
      if @colspan == 0
	style_sep = ''
	if multiline || aligned
	  style_sep = '|'
	  align += ' ' if multiline
	end
	trans = beg + align + rowspan + style_sep + @contents + "\n"
      elsif @colspan > 1
	align += ' ' if aligned
	rowspan += ' ' if multiline
	trans = "#{beg}#{align}#{rowspan}colspan=\"#{@colspan}\"|#{@contents}\n"
      end
    end
    #puts "to_mediawiki #{to_s} #{trans}"
    trans
  end
end

# classes describing the tables of a wiki {{{
class WikiCell
  attr_reader :colspan
  attr_reader :rowspan
  attr_reader :align
  attr_reader :text

  def initialize(wikistyle, wikitext)
    @colspan = 0
    @rowspan = 0
    @align = ''
    @text = wikitext
    #puts "WikiCell.new(\"#{wikistyle}\", \"#{wikitext}\")"
    unless wikistyle.nil?
      wikistyle.sub(/\bcolspan="(\d+)"/) { |style| @colspan = $1.to_i }
      wikistyle.sub(/\browspan="(\d+)"/) { |style| @rowspan = $1.to_i }
      wikistyle.sub(/\balign="(center|left|right)"/) { |style| @align = $1 }
    end
  end

  def docbook(colnum)
    doc = '<entry'
    if @colspan != 0
      doc << " namest=\"c#{colnum}\" nameend=\"c#{colnum + @colspan - 1}\""
    end
    doc << " morerows=\"#{@rowspan - 1}\" valign=\"middle\"" if @rowspan != 0
    doc << " align=\"#{@align}\"" if @align != ''
    doc << '>' << @text << '</entry>'
  end

  def nbcols
    [1, @colspan].max
  end
end

class WikiTable
  attr_reader :rows
  attr_reader :headers
  attr_reader :title
  attr_reader :nbcols

  def initialize(wikitext)
    @rows = []
    @headers = []
    @title = ''
    header = false
    row = nil
    #puts "=== WikiTable ===\n#{wikitext}\n-------\n"
    wikitext.each_line do |line|
      line.chomp!
      case line
      when /^[|]\+/ then line.sub(/^[|]\+(.*+)$/) { |line| @title = $1 }
      when /^!/ then
	line.sub(/^!([^|]+[|])?([^|]*)$/) do |line|
	  row << WikiCell.new($1, $2)
	  header = true
	end
      when /^[|][-}]$/ then
	if row.size != 0
	  if header
	    @headers << row
	  else
	    @rows << row
	  end
	  row = []
	end
      when /^[|]/ then
	line.sub(/^[|]([^|]+[|])?([^|]*)$/) do |line|
	  row << WikiCell.new($1, $2)
	  header = false
	end
      when /^\{[|]/ then row = []
      else
	puts "mediawiki error in table with line #{line}"
	exit 1
      end
    end
    nbcol = 0
    if @headers.size != 0
      @headers.first.each { |header| nbcol += header.nbcols }
    elsif @rows.size != 0
      @rows.first.each { |cell| nbcol += cell.nbcols }
    end
    @nbcols = nbcol
    #puts "#{nbcol} columns"
  end

  def docbook
    doc = '<table frame="all"><title>' << @title << '</title>' << "\n" <<
    '<tgroup cols="' << @nbcols.to_s << '" align="left" rowsep="1">' << "\n"
    (1..@nbcols).each do |num|
      strnum = num.to_s
      doc << '<colspec colnum="' << strnum << '" colname="c' << strnum << '"/>' << "\n"
    end
    if @headers.size != 0
      doc << "<thead>\n"
      @headers.each do |row|
	doc << "<row>\n"
	colnum = 1
	row.each { |cell| doc << cell.docbook(colnum); colnum += cell.nbcols }
	doc << "\n</row>\n"
      end
      doc << "</thead>\n"
    end
    if @rows.size != 0
      doc << "<tbody>\n"
      @rows.each do |row|
	doc << "<row>\n"
	colnum = 1
	row.each { |cell| doc << cell.docbook(colnum); colnum += cell.nbcols }
	doc << "\n</row>\n"
      end
      doc << "</tbody>\n"
    end
    doc << "</tgroup>\n</table>\n"
    #puts "DOCBOOK====\n#{doc}======="
    doc
  end

end

# end of the classes describing a wiki table for the translation into docbook }}}

class Tiddler
  private 
  attr_reader :docbook_begin
  attr_reader :docbook_end
  public
  attr_reader :tags
  attr_reader :title
  attr_reader :contents
  attr_reader :siblings
  attr_reader :no_title
  attr_reader :no_image
  attr_reader :no_file
  attr_accessor :kind # kind of docbook contents

  def initialize(title, tab_tags, text)
    #puts "new Tiddler: #{title} #{tab_tags}"
    @title = title
    @tags = tab_tags
    setup_kind
    @contents = tiddlywiki_to_mediawiki(text)
    inside = @contents[/^.*(?=\n+== sequential reading ==\n)/m]
    inside = @contents if inside.nil?
    #puts "inside=«#{inside}»"
    @docbook_begin, @docbook_end = mediawiki_to_docbook(inside)
    #puts "docbook is clean «#{@docbook_begin}#{@docbook_end}»"
    @siblings = []
  end

  def setup_kind
    first = ''
    @tags.each do |tag|
      if tag.start_with?(':')
	if first != ''
	  puts "tiddler \"#{@title}\" has more than one format tag: #{first} and #{tag}"
	  exit 1
	end
	first = tag
	case tag
	when ':part' then @kind = 'part'
	when ':chapter' then @kind = 'chapter'
	when ':section' then @kind = 'section'
	when ':simplesect' then @kind = 'simplesect'
	when ':note' then @kind = 'note'
	when ':tip' then @kind = 'tip'
	when ':caution' then @kind = 'caution'
	when ':important' then @kind = 'important'
	when ':warning' then @kind = 'warning'
	when ':appendix' then @kind = 'appendix'
	end
      end
    end
    @kind = 'section' if first == ''
  end

  def tiddlywiki_to_mediawiki(inside)
    #puts "=== tiddliwiki ===\n#{inside}\n-------(tiddlywiki_to_mediawiki)---"
    # the first regex in trans = could take very very long time (seeming like
    # if an infinite time) if there is only an odd number of couples of quotes
    # in the string.
    # So we fix it by adding a couple of quotes at the end if need be.
    kludge = inside.split("''", -1)
    if kludge.count & 1 == 0
      # special case with a couple of quotes at the end of the string
      if kludge[kludge.count - 1].length == 0
	inside = inside[0, inside.length - 2] # remove these last two quotes
      else
	inside << "''"
      end
    end
    trans = inside .
      gsub(/''((?:[^']+'?)*)''/, "'''\\1'''") .
      #gsub(/\/\/((?:[^\/]+\/?)*)\/\//, "''\\1''") . # bug: infinite loop with //dummy// for instance
      gsub(/\/\/([^\/]*)\/\//, "''\\1''") .          # doesn't allow / within italics
      gsub(/\[\[([^|\]]+)\|([^\]]+)\]\]/, '[[\2|\1]]') .
      gsub(/\[\[(https?:[^|\]]+)\|([^\]]+)\]\]/, '[\1 \2]') .
      gsub(/^!!!! *(.*)$/, '==== \1 ====') .
      gsub(/^!!! *(.*)$/, '=== \1 ===') .
      gsub(/^!! *(.*)$/, '== \1 ==') .
      gsub(/^! *(.*)$/, '= \1 =') .
      gsub(/\&lt;\/?nowiki\&gt;/, '') # nowiki is of use because of -- (which is not mediawiki code)
    #puts "before translate_img **************\n#{trans}\n-------"
    trans = translate_img(trans)
    #puts "=== step 1 ===\n#{trans}\n=======" ;
    trans = trans .
      gsub(/([~]?)([A-Z][0-9_-]*[a-z][a-z0-9_-]*[A-Z][A-Za-z0-9_-]*)/) {
      |camel| ($1 == '~') ? $2 : "[[#{$2}]]"
    } .
    gsub(/([~]?)([A-Z][0-9_-]*[A-Z]+[A-Z0-9_-]*[a-z][A-Za-z0-9_-]*)/) {
      |camel| ($1 == '~') ? $2 : "[[#{$2}]]"
    } .
    + ''; puts "=== step 2 ===\n#{trans}\n=======" ; trans = trans .
    # corrects [[[[HCh]]|Heavy Chariot]] for instance
    gsub(/\[\[(\[\[[A-Z][^\]]*)\]\]/, '\1') .
    # corrects [[PIG|[[PIGs]]]] for instance
    gsub(/\[\[([^\]|]+)\|\[\[([A-Z][^\]]*)\]{4}/, '[[\1|\2]]') .
    + ''; puts "=== step 3 ===\n#{trans}\n=======" ; trans = trans .
    gsub(/\[\[(\[\[ZoC)\]\]/, '\1') .
    gsub(/\[(https?:[^\[]+)\[\[([^\]]+)\]\]([^\]]*)\]/, '[\1\2\3]') .
    gsub(/(\[https?:)''/, '\1//')
    puts "****** before translate_table ********\n#{trans}\n-------"
    trans = translate_tables(trans)
    #puts 'translated!'
    trans
  end

  def translate_img(trans)
    @no_title = []
    @no_file = []
    file = ''
    #puts "tiddler #{@title} trans = #{trans}"
    newtrad = trans.gsub(/\[(\&[lg]t;)?img\[([^\]]*)\]\]/) do |img|
      align = $1
      desc = $2
      if desc =~ /^([^|]*)\|([^\]]*)$/
	file = Regexp.last_match(2)
	desc = Regexp.last_match(1)
      else
	file = desc
	@no_title << file
      end
      @no_file << file unless File.exists?(file)
      picture = "[[File:#{file}|#{desc}"
      picture << ((align == '&gt;') ? '|right' : '|left') if align != ''
      picture << '|thumb|300px]]'
      picture
    end
    @no_image = file === ''
    newtrad
  end

  def translate_tables(text)
    return text unless text.match(/^|/m)
    #puts "translate_tables of\n-----------\n#{text}\n------------"
    table = nil
    title = ''
    nb_headers_rows = 0
    state = 0
    trans = ''
    rownum = 0
    text.each_line do |line|
      if line.match(/^\|/)
	if state == 0
	  state = 1
	  table = []
	  title = ''
	  nb_headers_rows = 0
	  rownum = 0
	end
	if line.match(/^\|[^\|]+\|c$/)
	  line.chomp!
	  title = line.sub(/^.(.*).c$/, '\1')
	elsif line.match(/^\|.+\|h?$/)
	  line.chomp!
	  if line[-1] == 'h'
	    line.chop!
	    nb_headers_rows += 1
	    #puts "header : #{line}"
	  end
	  state = 2
	  hspan = line.match(/\|(?:&gt;|>)\|./)
	  vspan = line.match(/\|~\|./)
	  new_cells = []
	  if hspan.nil? && vspan.nil?
	    line[0..-2].gsub(/\|([^|]+)/) { |cell| new_cells << TiddlyCell.new($1) }
	  else
	    cells = line.split('|')
	    cells.delete_at(0)
	    colspan = 0
	    (1..cells.count).each do |cellnum|
	      cell = cells[cellnum - 1]
	      if cell == '&gt;' || cell == '>'
		# colspan on the column on the right
		colspan += 1
		translated_cell = TiddlyCell.new(cell, 1)
	      elsif cell == '~'
		# rowspan on the previous line
		if rownum == 0
		  puts "rowspan cannot be set on first table line (inc headers)."
		  exit 1
		end
		(1..rownum).each do |delta|
		  row = table[rownum - delta]
		  translated_cell = row[cellnum - 1]
		  unless translated_cell.rowspan == 1
		    translated_cell.inc_rowspan
		    table[rownum - delta][cellnum - 1] = translated_cell
		    break
		  end
		end
		translated_cell = TiddlyCell.new(cell, 0, 1)
	      elsif colspan != 0
		translated_cell = TiddlyCell.new(cell, colspan + 1)
		colspan = 0
	      else
		translated_cell = TiddlyCell.new(cell)
	      end
	      new_cells << translated_cell
	    end
	  end
	  table << new_cells
	  rownum += 1
	end
      else
	if (state != 0)
	  state = 0
	  trans += translate_tiddlytable(table, nb_headers_rows, title)
	end
	trans += line
      end
    end
    trans += translate_tiddlytable(table, nb_headers_rows, title) if state != 0
    #puts "=== table to mediawiki ===\n#{trans}\n==="
    trans
  end

  def translate_tiddlytable(table, nb_headers_rows, title)	
    trans = "{| class=\"wikitable\"\n"
    trans += "|+#{title}\n|-\n" if title != ''
    sep = ''
    beg = '!'
    nbh = nb_headers_rows
    table.each do |row|
      trans += sep
      sep = "|-\n"
      beg = '|' if nbh == 0
      nbh -= 1
      row.each { |cell| trans += cell.to_mediawiki(beg) }
    end
    trans += "|}\n"
    #puts "=== begin TABLE ===\n#{trans}=== end TABLE ==="
    trans
  end

  def mediawiki_to_docbook(inside)
    #print "mediawiki_to_docbook ====\n#{inside}\n\n"
    trans = inside .
      # (?: is non-capturing group within a regex. see http://www.regular-expressions.info/brackets.html
      # and http://www.regular-expressions.info/modifiers.html
      # *+ is possessive. * only could block the regexp motor and would be quite slower.
      gsub(/'''(([^']*|(?<!')')*+)'''/, "<emphasis role=\"strong\">\\1</emphasis>") .
      gsub(/''((?:[^']+'?)*)''/, "<emphasis>\\1</emphasis>") .
      gsub(/\[\[File:([^|]+)\|([^|]+)(\|right)?(\|left)?\|thumb\|\d*px\]\]/) do |picture|
	align = "align=\"left\" "
	figfile = $1
	figtitle = $2
	figid = figfile.gsub(/\.svg$/, '').gsub(/[\/.]+/, '_')
	#puts "vu #{figfile} :: #{figtitle} AS #{figid}"
	figure = "<figure xml:id=\"#{figid}\">\n<title>#{figtitle}</title>\n" <<
	"<mediaobject>\n<alt>#{figtitle}</alt>\n<imageobject>\n" <<
	"<imagedata #{align}format=\"SVG\" fileref=\"#{figfile}\"/>\n" <<
	"</imageobject>\n</mediaobject></figure>\n"
	#puts "Image translated into #{figure}"
	figure
      end .
      gsub(/\[\[([^\]|]+)\]\]/) { |match| lib = $1; dest = lib.gsub(/[^a-zA-Z0-9]+/, '_'); "<link linkend=\"#{dest}\">#{lib}</link>" }  .
      gsub(/\[\[([^|]+)\|([^\]]+)\]\]/) { |match| lib = $2; dest = $1.gsub(/[^a-zA-Z0-9]+/, '_'); "<link linkend=\"#{dest}\">#{lib}</link>" } .
      gsub(/\[([^ ]+) ([^\]]+)\]/) { |match| lib = $2; dest = $1; "<link xlink:href=\"#{dest}\">#{lib}</link>" } .
      gsub(/\n\n+/m, "\n</para>\n<para>\n")

      #puts "after regex trans=#{trans}\n-------------\n\n"
      trans = operate_headers(trans)
      trans = operate_definitions(trans)
      trans = operate_lists(trans)
      trans = operate_tables(trans)
      #puts "after operate trans=#{trans}\n-------------\n\n"
      #puts "DOCBOOK tiddler \"#{@title}\" as #{@kind}"
      # <part> forbids direct inclusion of text. So we have to put everything
      # but <title> and 'sequential reading' into <partinfo>.
      idxml = @title.gsub(/[^a-zA-Z0-9]+/, '_')
      left = "<#{@kind} xml:id=\"#{idxml}\">\n<title>#{@title}</title>\n"
      left << "<partintro>\n" if @kind == 'part'
      left << "<para>\n" << trans
      left << "\n</para>" unless trans.match(/<\/section>\n*$/m)
      left << "\n</partintro>\n" if @kind == 'part'
      right = "</#{@kind}>\n"
      return left, right
  end

  def self.analyze_header(line)
    line.sub(/^(=+) +(.*[^= ]) +=+$/) { |header| return $1.length, $2; }
    return 0, "BUG #{line}"
  end

  def operate_headers(inside)
    #puts "\n:::operate_headers:::\n#{inside}\n%%%(operate_headers)%%%\n"
    #inside.each_line { |line| print ">>> #{line}" }
    #puts "-----------------"
    trans = '';
    stack = Array.new
    inside.each_line do |line|
      #print "??? #{line}"
      if line.match(/^=+[^=].*=+$/)
	line_level, title = Tiddler.analyze_header(line)
	#puts "TITRE @#{line_level} :::#{title}::: #{line}"
	#p stack
	unless stack.empty?
	  level = stack.pop
	  #puts "--> #{level} % #{line_level}"
	  if (level >= line_level)
	    trans << "\n</para>" unless trans[-11..-1] == "</section>\n"
	    while (level >= line_level)
	      trans << "</section>\n"
	      break if stack.empty?
	      level = stack.pop
	    end
	  end
	  stack.push(level) if level < line_level
	  stack.push(line_level)
	  #print "while proceding: "
	  #p stack
	end
	stack.push(line_level) if stack.empty?
	trans << "\n</para>" unless trans[-11..-1] == "</section>\n"
	trans << "\n<section>\n<title>#{title}</title>\n\<para>\n"
	#puts "%%%% #{title} %%%% #{trans}\n------------\n"
	#print "after: "
	#p stack
      else
	trans << line
      end
    end
    #puts "=== END OF CONTENTS ===\n#{trans}\n^^^^ CONTENTS ^^^^"
    unless stack.empty?
      trans << "\n</para>" unless trans[-11..-1] == "</section>\n"
      while (!stack.empty?)
	stack.pop
	trans << "\n</section>\n"
      end
    end
    trans
  end

  def self.analyze_list(line)
    line.gsub(/^([#*]+) *(.*)$/) { |header|
      return $1, $2.strip;
    }
  end


  def operate_definitions(inside)
    #{{{
    within_list = false
    within_term = false
    trans = '';
    inside.each_line { |line|
      line.chomp!
      if line.match(/^;/)
	if within_list
	  trans << "</listitem>\n" unless within_term
	  trans << "</varlistentry>\n"
	else
	  within_list = true
	  trans << "<variablelist>\n"
	end
	unless within_term
	  trans << "<varlistentry>\n"
	  within_term = true
	end
	line.gsub!(/^; *(.*)$/, '<term>\1</term>')
      elsif line.match(/^:/) && within_list
	if within_term
	  trans << "<listitem>\n"
	  within_term = false
	end
	line.gsub!(/^: *(.*)$/, '<para>\1</para>')
      elsif within_list
	trans << "</listitem>\n" unless within_term
	trans << "</varlistentry>\n</variablelist>\n"
	within_term = false
	within_list = false
      end
      trans << line << "\n"
    }
    if within_list
      trans << "</listitem>\n" unless within_term
      trans << "</varlistentry>\n</variablelist>\n"
    end
    trans
  end #}}}

  def operate_lists(inside)
    #{{{
    #puts "======="
    trans = '';
    stack = Array.new
    inside.each_line { |line|
      #print "LIGE:#{line}"
      if line.match(/^[#*]/)
	marker, item = Tiddler.analyze_list(line)
	line_level = marker.length
	ordered = marker[-1, 1] == '#'
	if stack.empty?
	  #puts "STACK EMPTY"
	  stack.push(marker)
	  list = ordered ? 'orderedlist' : 'itemizedlist';
	  trans << "<#{list}>\n"
	else
	  marker = stack.pop
	  level = marker.length
	  #puts "STACK:#{marker} @ #{level} % #{line_level}\n"
	  if (level < line_level)
	    #puts "ORDERED:#{ordered} #{marker}"
	    stack.push(marker)
	    #p stack
	    #puts "trans=#{trans}"
	    list = ordered ? 'orderedlist' : 'itemizedlist';
	    trans << "\n<#{list}>\n"
	  else
	    while (level > line_level)
	      ordered = marker[-1, 1] == '#'
	      list = ordered ? 'orderedlist' : 'itemizedlist';
	      trans << "\n</para>\n</listitem>\n"
	      trans << "</#{list}>"
	      break if stack.empty?
	      marker = stack.pop
	      level = marker.length
	    end
	    trans << "\n</para>\n</listitem>\n"
	  end
	  stack.push(marker)
	end
	trans << "<listitem>\n<para>\n#{item}"
      else
	trans << "\n" unless stack.empty?
	while (!stack.empty?)
	  marker = stack.pop
	  level = marker.length
	  ordered = marker[-1, 1] == '#'
	  list = ordered ? 'orderedlist' : 'itemizedlist';
	  trans << "\n</para>\n</listitem>\n"
	  trans << "</#{list}>\n"
	end
	trans << line
      end
      #p stack
    }
    #puts "END"
    trans << "\n" unless stack.empty?
    while (!stack.empty?)
      marker = stack.pop
      #level = marker.length
      #puts "STACK:#{marker} @ #{level}\n"
      ordered = marker[-1, 1] == '#'
      list = ordered ? 'orderedlist' : 'itemizedlist';
      trans << "\n</para>\n</listitem>\n"
      trans << "</#{list}>\n"
    end
    trans
  end #}}}

  def operate_tables(inside)
    #{{{
    #puts "======="
    trans = '';
    incorporate = false
    table_text = ''
    inside.each_line do |line|
      #puts "LIGNE:#{incorporate}:#{line}"
      if !incorporate 
	if line.match(/^\{[|].*+/)
	  incorporate = true
	  table_text = line
	else
	  trans << line
	end
      elsif incorporate
	table_text << line
	if line == "|}\n"
	  incorporate = false
	  #puts "running %%%%%%%%%%%%%"
	  table = WikiTable.new(table_text)
	  trans << table.docbook
	  table_text = ''
	end
      end
    end
    if incorporate
      #puts "final %%%%%%%%%%%%%%%%%"
      table = WikiTable.new(table_text)
      trans << table.docbook
    end
    trans
  end #}}}

  def self.analyze_tags(htiddlers)
    # bad_tag : list of every bad format tag (form of the tiddler in the docbook)
    bad_tag = Hash.new

    # htagged : list of all tags declared in at least a tiddler 
    # (such a tag must also be the title of a tiddler).
    htagged = Hash.new
    htiddlers.each_value do |tiddler|
      tiddler.tags.each do |tag|
	if tag.start_with?(':')
	  unless tag.match(/^:(chapter|section|simplesect|note|tip|caution|warning|important|appendix|part)$/)
	    if bad_tag.has_key?(tag)
	      bad_tag[tag] << tiddler.title
	    else
	      bad_tag[tag] = [tiddler.title]
	    end
	  end
	else
	  if htagged.has_key?(tag)
	    htagged[tag] << tiddler
	  else
	    htagged[tag] = [tiddler]
	  end
	end
      end
    end
    # tagless: list of all tiddlers without any tag
    tagless = Array.new
    htiddlers.each_value { |tiddler| tagless << tiddler.title unless tiddler.tags.grep(/^[^:]/).size > 0 }
    # the head tiddler must be removed from tagless. This is the only one 
    # with the :part tag (and it's its only tag).
    tagless = tagless.reject do |title|
      tags = htiddlers[title].tags
      tags.size == 1 && tags[0] == ':part'
    end

    # no_tag : list of every tag that are not corresponding to any tiddler title
    # (which is wrong).
    no_tag = Array.new
    htagged.each_key { |title| no_tag << title unless htiddlers.has_key?(title) }

    tagless = tagless.sort{|a, b| a.casecmp(b)}
    no_tag = no_tag.sort{|a, b| a.casecmp(b)}
    return tagless, no_tag, bad_tag
  end

  # recursive management of 'sequential reading'
  def sequentialize(htiddlers, hseq = Hash.new, repeated = Array.new, unknowns = Array.new)
    sequence = @contents[/\n== sequential reading ==\n.*/m]
    #puts "sequentialize(#{@title})"
    if sequence.nil? && @tags.size == 1 && @tags[0] == ':part'
      print "The initial tiddler \"#{@title}\" has no sequential reading!\n"
      exit 1
    end
    return Hash.new, [], [] if sequence.nil?

    sibling = Array.new
    num = 0
    sequence.each_line do |line|
      num += 1
      if (num > 2 && line != "\n")
	#print "line=«#{line}»\n"
	tiddler = line.gsub(/^([*#] )?(\[\[)?([^\]|]*)(\]\])?$/, '\3').
	  gsub(/^([*#] )?\[\[([^|]*)\|[^\]]*\]\]$/, '\2').chomp
	    if (hseq.has_key?(tiddler))
	      msg = "Error, tiddler \"#{tiddler}\" included twice, first by \"" <<
	      hseq[tiddler] << "\" and then by \"" << @title << "\"\n"
	      repeated << msg
	    elsif (htiddlers.has_key?(tiddler))
	      hseq[tiddler] = @title
	      sibling << tiddler
	    else
	      msg = "Error, unknown tiddler \"#{tiddler}\" in sequence of tiddler \"" <<
	      @title << "\"\n" 
	      unknowns << msg
	    end
      end
    end
    @siblings = sibling
    #sibling.each { |tiddler| print @title + " : includes «#{tiddler}»\n" }
    sibling.each do |tiddler|
      htiddlers[tiddler].sequentialize(htiddlers, hseq, repeated, unknowns)
    end
    return hseq, repeated, unknowns
  end

  def self.analyze_sequential_reading(htiddlers)
    head_tiddler = htiddlers['']
    return nil, nil, nil, nil, nil, nil if head_tiddler.nil?
    hseq, repeated, unknowns = head_tiddler.sequentialize(htiddlers)
    # checking that no tiddler has ben left apart.
    pas_inclus = []
    htiddlers.each_key do |titre|
      pas_inclus << titre unless hseq.has_key?(titre)
    end
    pas_inclus.delete(head_tiddler.title)
    # missing_tag : list of every tiddler without a tag corresponding
    # to a tiddler that link the former tiddler in its 'sequential reading' list
    missing_tag = Array.new
    self_tag = Array.new
    htiddlers.each_value do |tiddler|
      got_it = false
      tiddler.tags.each do |tag|
	parent = htiddlers[tag]
	unless (parent.nil?)
	  siblings = parent.siblings
	  #puts "\"#{tiddler.title}\" tag \"#{tag}\" @#{siblings}"
	  if (!siblings.nil? && siblings.include?(tiddler.title))
	    got_it = true
	    break
	  end
	end
      end
      missing_tag << tiddler.title unless got_it
      self_tag << tiddler.title if tiddler.tags.include?(tiddler.title)
    end
    missing_tag.delete(head_tiddler.title)
    missing_tag = missing_tag.sort{|a, b| a.casecmp(b)}
    self_tag = self_tag.sort{|a, b| a.casecmp(b)}
    return pas_inclus, repeated, unknowns, missing_tag, self_tag, head_tiddler
  end

  def self.analyse_pictures(htiddlers)
    tiddler = htiddlers['']
    return nil, nil, nil if tiddler.nil?
    without_picture = []
    without_title = []
    without_file = []
    htiddlers.each_value do |tiddler|
      titre = tiddler.title
      without_picture << "no picture in tiddler \"#{titre}\".\n" if tiddler.no_image && tiddler.title =~ /^fig:/
      tiddler.no_title.each do |file|
	without_title << "no alt title for picture file \"#{file}\" in tiddler \"#{titre}\".\n"
      end
      tiddler.no_file.each do |file|
	without_title << "file not found in tiddler \"#{titre}\": \"#{file}\".\n"
      end
    end
    return without_picture, without_title, without_file
  end

  def wiki_single(htiddlers, without_title = false)
    wiki = ''
    wiki << "== #{@title} ==\n" unless without_title
    if @siblings.nil? || @siblings.size == 0
      wiki << @contents << "\n"
    else
      wiki << @contents[/^.*(?=\n+== sequential reading ==\n)/m] << "\n"
      @siblings.each { |title| wiki << htiddlers[title].wiki_single(htiddlers) }
    end
    wiki
  end

  def write_wiki_files(rep, htiddlers, without_title = false)
    list = @title
    target = "#{rep}#{@title}"
    File.open(target, 'w') do |dest|
      dest.puts("== #{@title} ==") unless without_title
      if @siblings.nil? || @siblings.size == 0
	dest.puts @contents
      else
	dest.puts @contents[/^.*(?=\n+== sequential reading ==\n)/m]
	@siblings.each do |title|
	  list << "\n" << htiddlers[title].write_wiki_files(rep, htiddlers)
	end
      end
    end
    list
  end

  def docbook(htiddlers, intro_data, init = false)
    sep = "\n"
    inside = ''
    inside = init_docbook(intro_data) if init
    inside << @docbook_begin
    unless @siblings.nil? || @siblings.size == 0
      sep = ''
      @siblings.each do |title|
	inside << htiddlers[title].docbook(htiddlers, intro_data)
      end
    end
    inside << sep << @docbook_end
    inside << finish_docbook if init
    inside
  end

  def init_docbook(intro_data)
    xml_author = ''
    intro_data['authors'].each do |author|
      xml_author <<       
      '    <author>' << "\n" <<
      '      <personname>' << "\n" <<
      "        <firstname>#{author['firstname']}</firstname>\n" <<
      "        <surname>#{author['surname']}</surname>\n" <<
      '      </personname>' << "\n" <<
      '      <affiliation>' << "\n" <<
      "        <address><email>#{author['email']}</email></address>\n" <<
      '      </affiliation>' << "\n" <<
      '    </author>' << "\n"
    end

    legalese = intro_data['legalese']
    puts "legalese = " << legalese
    puts "title = " << intro_data['title']
    puts "subtitle = " << intro_data['subtitle']
    '<?xml version="1.0" encoding="utf-8"?>' << "\n" <<
    '<book xml:lang="fr" xmlns="http://docbook.org/ns/docbook" version="5.0"' << "\n" <<
    '     xmlns:xlink="http://www.w3.org/1999/xlink"' << "\n" <<
    '     xmlns:svg="http://www.w3.org/2000/svg"' << "\n" <<
    '     xmlns:html="http://www.w3.org/1999/xhtml"' << "\n" <<
    '     xmlns:db="http://docbook.org/ns/docbook">' << "\n" <<
    '  <info>' << "\n" <<
    "    <title>#{intro_data['title']}</title>\n" <<
    "    <subtitle>#{intro_data['subtitle']}</subtitle>\n" <<
    xml_author <<
    "    <pubdate>#{intro_data['pubdate']}</pubdate>\n" <<
    '    <legalnotice>' << "\n" <<
    "      <para>\n#{legalese}\n</para>\n" <<
    '    </legalnotice>' << "\n" <<
    '  </info>' << "\n"
  end

  def finish_docbook
    "</book>\n"
  end
end
