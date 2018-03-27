# transcript tiddlywiki into mediawiki then into docbook
#
# copyright 2013-2015 Jean-Pierre Rivière <jn.pierre.riviere (at) gmail.com>

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

require_relative 'i18n'
require_relative 'entities'

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
	puts "mediawiki error in table \"#{@title}\" with line \"#{line}\""
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
    #puts "#{@title} tiddliwiki translated to mediawiki ===#{@contents}==="
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
	when ':appendix' then @kind = 'appendix'
	when ':note' then @kind = 'note'
	when ':footnote' then @kind = 'footnote'
	when ':tip' then @kind = 'tip'
	when ':caution' then @kind = 'caution'
	when ':important' then @kind = 'important'
	when ':warning' then @kind = 'warning'
	end
      end
    end
    @kind = 'section' if first == ''
  end

  def immediate?
    immediate = false
    case @kind
    when 'note' then immediate = true
    when 'footnote' then immediate = true
    when 'tip' then immediate = true
    when 'caution' then immediate = true
    when 'important' then immediate = true
    when 'warning' then immediate = true
    end
    immediate
  end

  def fix_couple_quotes(inside)
    # the first regex in trans = could take very very long time (seeming like
    # if an infinite time) if there is only an odd number of couples of quotes
    # in the string.
    # So we fix it by adding a couple of quotes at the best place we can guess.
    kludge = inside.split("''", -1)
    if kludge.count & 1 == 0
      puts "Error: lacking a couple of quotes in tiddler \"#{@title}\"."
      #puts "current inside=#{inside}====="
      if kludge[kludge.count - 1].length == 0
         # special case with a couple of quotes at the end of the string
	inside = inside[0, inside.length - 2] # remove these last two quotes
      else
	# general case. The fix should work good enough most of the time.
	inside.sub!(/(''(?![^']+'').*)/m) do |last_couple|
	  # we have all the text from the last couple of quotes on
	  text = $1
	  # put 2 quotes at the first end of line after it or at the end of text
	  text.sub!(/($)/m, '\'\'\1')
	end
      end
    end
    inside
  end

  def tiddlywiki_to_mediawiki(inside)
    #puts "=== raw ===\n#{inside}\n======="
    inside = fix_couple_quotes(inside)
    #puts "=== step 0 ===\n#{inside}\n======="
    trans = inside .
      gsub(/''((?:[^']+'?)*)''/, "'''\\1'''") .
      gsub(/\/\/([^\/]*)\/\//, "''\\1''") . # doesn't allow / within italics
      gsub(/\[\[([^|\]]+)\|([^\]]+)\]\]/, '[[\2|\1]]') .
      gsub(/\[\[(https?:[^|\]]+)\|([^\]]+)\]\]/, '[\1 \2]') .
      gsub(/^!!!! *(.*)$/, '==== \1 ====') .
      gsub(/^!!! *(.*)$/, '=== \1 ===') .
      gsub(/^!! *(.*)$/, '== \1 ==') .
      gsub(/^! *(.*)$/, '= \1 =') .
      gsub(/@@([^@]*)@@/, '<code>\1</code>') .
      gsub(/\&lt;\/?nowiki\&gt;/, '') . # nowiki is of use because of -- (which is not mediawiki code)
      # Handle non breaking space entities into non breaking spaces.
      # Other entites are dysfunctional, but we don't know how to support entities in docbook yet.
      gsub(/\&amp;([a-zA-Z]+);/) { |match| (Entities.instance.include($1)) ? "\&#{$1};" : $& }
    #puts "before translate_img #{@title} **************\n#{trans}\n-------"
    trans = translate_img(trans)
    #puts "=== step 1 #{@title} ===\n#{trans}\n======="
    # fixing camelcase automatic links. but anywhere: further correcting needed
    trans = trans .
      gsub(/([~]?)([A-Z][0-9_-]*[a-z][a-z0-9_-]*[A-Z][A-Za-z0-9_-]*)/) {
      |camel| ($1 == '~') ? $2 : "[[#{$2}]]"
    } .
    gsub(/([~]?)([A-Z][0-9_g-]*[A-Z]+[A-Z0-9_-]*[a-z][A-Za-z0-9_-]*)/) {
      |camel| ($1 == '~') ? $2 : "[[#{$2}]]"
    } .
    #+ ''; puts "=== step 2 #{@title} ===\n#{trans}\n=======" ; trans = trans .
    # corrects [[[[HCh]]|Heavy Chariot]] for instance
    gsub(/\[\[(\[\[[A-Z][^\]]*)\]\]/, '\1') .
    # corrects [[PIG|[[PIGs]]]] for instance
    gsub(/\[\[([^\]|]+)\|\[\[([A-Z][^\]]*)\]{4}/, '[[\1|\2]]') .
    #+ ''; puts "=== step 3 #{@title} ===\n#{trans}\n=======" ; trans = trans .
    gsub(/\[\[(\[\[ZoC)\]\]/, '\1')
    #puts "=== step 4 #{@title} ===\n#{trans}\n======="
    # fix [http://www.fubar.com [[ForSale]] here] into [http://www.fubar.com ForSale here]
    # fixing repeated while it's acting because several camelcase words may lurk
    fixing = true
    while (fixing) do
      fixing = false
      trans.gsub!(/\[([a-z]{3,8}:[^\]\[]+)\[{2}([^\]]+)\]{2}([^\]]*)\]/) do |str|
	fixing = true
	'[' << $1 << $2 << $3 << ']'
      end
    end
    #gsub(/\[([a-z]{3,8}:[^\[\]]+)\[{2}([^\]]+)\]{2}([^\]]*)\]/, '[\1\2\3]') .
    #puts "=== step 5 #{@title} ===\n#{trans}\n======="# ; trans = trans .
    trans.gsub!(/(\[[a-z]{3,8}:)''/, '\1//')
    #puts "=== step 6 #{@title} ===\n#{trans}\n======="
    trans = translate_tables(trans)
    # restore html entities
    #puts "=== final #{@title} ===\n#{trans}\n======="
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
      @no_file << file unless File.exists?('../schemas/' << file) || File.exists?(file)
      picture = "[[File:#{file}|#{desc}"
      picture << ((align == '&gt;') ? '|right' : '|left') if align != ''
      picture << '|thumb|300px]]'
      picture
    end
    @no_image = file === ''
    newtrad
  end

  # translate tiddlywiki tables into objects for later tranlation into mediawiki
  def translate_tables(text)
    #{{{
    return text unless text.match(/^|/m)
    #puts "translate_tables of #{@title}\n-----------\n#{text}\n------------"
    protector = /(\[\[[^\]\|]+)\|([^\]\|]+\]\])/
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
	if line.match(/^\|.+\|c$/)
	#if line.match(/^\|[^\|]+\|c$/)
	  line.chomp!
	  title = line.sub(/^.(.*).c$/, '\1')
	elsif line.match(/^\|.+\|h?$/)
	  line.chomp!
	  if line[-1] == 'h'
	    line.chop!
	    nb_headers_rows += 1
	    #puts "header : #{line}"
	  end
          protected_line = line.gsub(protector, '\1{@&@}\2')
          smart = protected_line != line
	  state = 2
	  hspan = line.match(/\|(?:&gt;|>)\|./)
	  vspan = line.match(/\|~\|./)
	  new_cells = []
	  if hspan.nil? && vspan.nil?
            #puts "TABLE NOSPAN #{@title} : #{protected_line}" if smart 
            unless smart
	      protected_line[0..-2].gsub(/\|([^|]+)/) { |cell| new_cells << TiddlyCell.new($1) }
            else
	      protected_line[0..-2].gsub(/\|([^|]+)/) do |cell|
                contents = $1.gsub(/\{@&@\}/, '|')
                #puts "TABLE SUBST #{@title} : #{contents}"
                new_cells << TiddlyCell.new(contents)
              end
            end
	  else
            #puts "TABLE SPAN #{@title} : #{protected_line}" if smart
	    cells = protected_line.split('|')
	    cells.delete_at(0)
	    colspan = 0
	    (1..cells.count).each do |cellnum|
	      cell = cells[cellnum - 1]
              cell.gsub!(/\{@&@\}/, '|') if smart
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
	  trans << translate_tiddlytable(table, nb_headers_rows, title)
	end
	trans << line
      end
    end
    trans << translate_tiddlytable(table, nb_headers_rows, title) if state != 0
    #puts "=== table to mediawiki for #{@title} ===\n#{trans}\n==="
    trans
  #}}}
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
    trans << "|}\n"
    #puts "=== begin TABLE in #{@title} ===\n#{trans}=== end TABLE in #{@title} ==="
    trans
  end

  # translate contents to docbook
  #
  # @param tiddlers Hash
  #	 hashtable of all the tiddlers
  def translate_to_docbook(tiddlers)
    @docbook_begin, @docbook_end = mediawiki_to_docbook(tiddlers)
    puts "TRANS #{@title} DOCBOOK #{@docbook_begin}=== END" 
  end

  # create a docbook link or insert immediate contents
  #
  # @param target string
  #	  wiki name of the linked resource
  # @param label string
  #	  label of the link
  # @param tiddlers hash
  #	  all the tiddlers in the document
  # @return string
  #	  translation for docbook according to the nature of the linked tiddler
  def wikilink_to_docbook(target, label, tiddlers)
    #puts "now in wikilink_to_docbook(#{target}, #{label}) for #{@title}"
    trans = ''
    linked = tiddlers[target]
    #puts "link to \"#{target}\" as label \"#{label}\" is " << linked.inspect
    if !linked
      trans = "error: unknown wikilink target \"#{target}\""
      puts trans
    elsif linked.immediate?
      left, right = linked.mediawiki_to_docbook(tiddlers)
      if (linked.kind == 'footnote')
	trans = "#{left}#{right}"
      else
	trans = "</para>#{left}#{right}<para>"
      end
    else
      target_id = target.gsub(/[^a-zA-Z0-9]+/, '_')
      trans = "<link linkend=\"#{target_id}\">#{label}</link>"
    end
    #puts "wikilink_to_docbook in \"#{@title}\" of \"#{target}\" is :::#{trans}:::#{target}:::"
    trans
  end

  def mediawiki_to_docbook(tiddlers)
    seqread = International.instance.sequential_reading
    regexp = Regexp.new('.*(?=\n+== ' + Regexp.escape(seqread) + ' ==\n)', Regexp::MULTILINE)
    inside = @contents[regexp]
    #inside = @contents[/^.*(?=\n+== sequential reading ==\n)/m]
    inside = @contents if inside.nil?
    #puts "mediawiki_to_docbook of #{@title}, inside ====\n#{inside}\n===="
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
	#puts "seen #{figfile} :: #{figtitle} AS #{figid}"
	figure = "<figure xml:id=\"#{figid}\">\n<title>#{figtitle}</title>\n" <<
	"<mediaobject>\n<alt>#{figtitle}</alt>\n<imageobject>\n" <<
	"<imagedata #{align}format=\"SVG\" fileref=\"#{figfile}\"/>\n" <<
	"</imageobject>\n</mediaobject></figure>\n"
	#puts "Image translated into #{figure}"
	figure
      end .
      gsub(/\[\[([^\]|]+)\]\]/) { |match| target = $1; wikilink_to_docbook(target, target, tiddlers) } .
      gsub(/\[\[([^|]+)\|([^\]]+)\]\]/) { |match| target = $1; label = $2; wikilink_to_docbook(target, label, tiddlers) } .
      gsub(/\[([^ ]+) ([^\]]+)\]/) do |match|
	target = $1
	label = $2
	#puts "xlink \"#{label}\" TO \"#{target}\""
	"<link xlink:href=\"#{target}\">#{label}</link>"
      end .
      gsub(/\n\n+/m, "\n</para>\n<para>\n")

      #puts "after regex \"#{@title}\" trans=#{trans}\n-------------\n\n"
      trans = operate_headers(trans)
      #puts "after operate_headers \"#{@title}\" trans=#{trans}\n-------------\n\n"
      trans = operate_definitions(trans)
      #puts "after operate_definitions \"#{@title}\" trans=#{trans}\n-------------\n\n"
      trans = operate_tables(trans)
      #puts "after operate_tables \"#{@title}\" trans=#{trans}\n-------------\n\n"
      trans = operate_lists(trans)
      #puts "after operate_lists \"#{@title}\" trans=#{trans}\n-------------\n\n"
      #puts "DOCBOOK tiddler \"#{@title}\" as #{@kind}"
      # <part> forbids direct inclusion of text. So we have to put everything
      # but <title> and 'sequential reading' into <partinfo>.
      idxml = @title.gsub(/[^a-zA-Z0-9]+/, '_')
      left = ''
      if (immediate?)
	left << "<#{@kind}>\n<para>\n" << trans << "</para>\n"
      else
	left << "<#{@kind} xml:id=\"#{idxml}\">\n"
	left << "<title>#{@title}</title>\n"
	left << "<partintro>\n" if @kind == 'part'
	left << "<para>\n" << trans
	left << "\n</para>" unless trans.match(/<\/section>\n*$/m)
	left << "\n</partintro>\n" if @kind == 'part'
      end
      right = "</#{@kind}>\n"
      #puts "mediawiki_to_docbook of #{@title}, translated ====\n#{left}#{right}\n===="
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
      #puts (within_list?'L':'-') + (within_term?'T':'-') + " >>#{line}<<"
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

  # translate mediawiki lists into docbook speaking
  def operate_lists(inside)
    #{{{
    #puts "=== operate_lists of #{@title} ===="
    trans = '';
    stack = Array.new
    inside.each_line do |line|
      line.chomp!
      if line.match(/^[#*]/)
        #puts "list LINE:>>#{line}<<"
	marker, item = Tiddler.analyze_list(line)
	line_level = marker.length
	ordered = marker[-1, 1] == '#'
	if stack.empty?
	  #puts "STACK was EMPTY"
	  stack.push(marker)
	  list = ordered ? 'orderedlist' : 'itemizedlist';
	  trans << "<#{list}>\n"
	else
	  stacked_marker = stack.pop
	  stacked_level = stacked_marker.length
	  #puts "list STACK:#{stacked_marker} @ #{stacked_level} % #{marker} @ #{line_level}\n"
	  if stacked_level < line_level
	    list = ordered ? 'orderedlist' : 'itemizedlist';
	    #print "list new #{list} #{marker} >> "
	    stack.push(stacked_marker)
	    #p stack
	    trans << "\n<#{list}>\n"
	  else
	    while (stacked_level > line_level)
	      ordered = stacked_marker[-1, 1] == '#'
	      list = ordered ? 'orderedlist' : 'itemizedlist';
	      trans << "\n</para>\n</listitem>\n</#{list}>"
	      #puts "list back #{marker} #{list}"
	      break if stack.empty?
	      stacked_marker = stack.pop
	      stacked_level = stacked_marker.length
	    end
	    trans << "\n</para>\n</listitem>\n"
	  end
	  stack.push(marker)
	end #stack.empty?
	trans << "<listitem>\n<para>\n#{item}"
      else # line.match
        # the table is over
	trans << "\n" unless stack.empty?
	#puts "list clear stack NOW."
	while (!stack.empty?)
	  marker = stack.pop
	  line_level = 0 # just nicer for clarity's sake
	  ordered = marker[-1, 1] == '#'
	  list = ordered ? 'orderedlist' : 'itemizedlist';
	  trans << "\n</para>\n</listitem>\n</#{list}>\n"
	end
	trans << line
      end
      #p stack
    end # inside.each_line
    #puts "list END"
    trans << "\n" unless stack.empty?
    while (!stack.empty?)
      marker = stack.pop
      #puts "further list STACK:#{marker} @ #{marker.length}\n"
      ordered = marker[-1, 1] == '#'
      list = ordered ? 'orderedlist' : 'itemizedlist';
      trans << "\n</para>\n</listitem>\n</#{list}>\n"
    end
    #puts "FINAL LIST::#{trans}::"
    trans
  end #}}}

  def operate_tables(inside)
    #{{{
    #puts "======="
    trans = '';
    incorporate = false
    table_text = ''
    inside.each_line do |line|
      #puts "table \"#{@title}\" LINE:#{incorporate}:#{line}"
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

  # find orphan links, that should have had a corresponding tiddler each one.
  def self.analyze_links(htiddlers)
    # orphans: list of orphans links
    orphans = Hash.new
    htiddlers.each_value do |tiddler|
      # we discard link to external files in our wikilink roundup.
      tiddler.contents.gsub(/\[\[(?!File:)([^\]\|]+)(?:\|(?:[^\]]+))?\]\]/) { |wikilink|
        ref = $1
        unless htiddlers.has_key?(ref)
          if orphans.has_key?(ref)
            orphans[ref] << tiddler.title
          else
            orphans[ref] = [tiddler.title]
          end
        end
      }
    end
    return orphans
  end

  def self.analyze_tags(htiddlers)
    # bad_tag : list of every bad format tag (form of the tiddler in the docbook)
    bad_tag = Hash.new
    # htagged : list of all tags declared in at least a tiddler 
    # (such a tag must also be the title of a tiddler).
    htagged = Hash.new
    htiddlers.each_value do |tiddler|
      tiddler.tags.each do |tag|
	if tag.start_with?(':')
	  unless tag.match(/^:(chapter|section|simplesect|(?:foot)?note|tip|caution|warning|important|appendix|part)$/)
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
    htiddlers.each_value do |tiddler|
      unless tiddler.immediate?
	tagless << tiddler.title unless tiddler.tags.grep(/^[^:]/).size > 0
      end
    end
    # the head tiddler must be removed from tagless. This is the only one 
    # with the :part tag (and it's its only tag).
    tagless = tagless.reject do |title|
      tags = htiddlers[title].tags
      tags.size == 1 && tags[0] == ':part'
    end

    # no_tag : list of every tag that is not corresponding to any tiddler title
    # (which is wrong).
    #no_tag = Array.new
    #htagged.each_key { |title| no_tag << title unless htiddlers.has_key?(title) }
    no_tag = Hash.new
    htagged.each_key do |tag|
      unless htiddlers.has_key?(tag)
	titles = Array.new
	htagged[tag].each { |tiddler| titles << tiddler.title }
	no_tag[tag] = titles.sort{|a, b| a.casecmp(b)}
      end
    end
    tagless = tagless.sort{|a, b| a.casecmp(b)}
    return tagless, no_tag, bad_tag
  end

  # recursive management of 'sequential reading'
  def sequentialize(htiddlers, hseq = Hash.new, repeated = Array.new,
		    linking_imm = Array.new, unknowns = Array.new)
    seqread = International.instance.sequential_reading
    regexp = Regexp.new('\n== ' + Regexp.escape(seqread) + ' ==\n.*', Regexp::MULTILINE)
    if @contents.nil?
      puts "sequentialize: no contents defined for tiddler #{@title}"
      puts "contents=#{@contents}"
      exit 1
    end
    sequence = @contents[regexp]
    #sequence = @contents[/\n== sequential reading ==\n.*/m]
    #puts "sequentialize(#{@title})"
    if sequence.nil? && @tags.size == 1 && @tags[0] == ':part'
      puts "The initial tiddler \"#{@title}\" has no sequential reading!"
      exit 1
    end
    return Hash.new, [], [], [], [] if sequence.nil?

    sibling = Array.new
    num = 0
    sequence.each_line do |line|
      num += 1
      if (num > 2 && line != "\n")
	#puts "line=«#{line}»"
	tiddler = line.gsub(/^([*#] )?(\[\[)?([^\]|]*)(\]\])?$/, '\3').
	  gsub(/^([*#] )?\[\[([^|]*)\|[^\]]*\]\]$/, '\2').chomp
	    if (hseq.has_key?(tiddler))
	      msg = "Error, tiddler \"#{tiddler}\" included twice, first by \"" <<
	      hseq[tiddler] << "\" and then by \"" << @title << "\"\n"
	      repeated << msg
	    elsif (htiddlers.has_key?(tiddler))
	      if (htiddlers[tiddler].immediate?)
		msg = "Error, immediate tiddler \"#{tiddler}\" in sequence of tiddler \"" <<
		@title << "\"\n" 
		linking_imm << msg
	      else
		hseq[tiddler] = @title
		sibling << tiddler
	      end
	    else
	      msg = "Error, unknown tiddler \"#{tiddler}\" in sequence of tiddler \"" <<
	      @title << "\"\n" 
	      unknowns << msg
	    end
      end
    end
    @siblings = sibling
    #sibling.each { |tiddler| puts @title + " : includes «#{tiddler}»" }
    sibling.each do |tiddler|
      htiddlers[tiddler].sequentialize(htiddlers, hseq, repeated, linking_imm, unknowns)
    end
    return hseq, repeated, linking_imm, unknowns
  end

  def self.analyze_sequential_reading(htiddlers)
    head_tiddler = htiddlers['']
    return nil, nil, nil, nil, nil, nil if head_tiddler.nil?
    #puts "analyze_sequential_reading of #{@title}"
    hseq, repeated, linking_imm, unknowns = head_tiddler.sequentialize(htiddlers)
    # checking that no tiddler has been left apart.
    not_there = []
    htiddlers.each_key do |titre|
      unless hseq.has_key?(titre)
	tiddler = htiddlers[titre]
	not_there << titre unless tiddler.immediate?
      end
    end
    not_there.delete(head_tiddler.title)
    # missing_tag: list of every non-immediate tiddler without a tag
    # corresponding to the tiddler that links to it
    # in its 'sequential reading' list.
    # self_tag: list of tiddlers tagging themselves.
    missing_tag = Array.new
    self_tag = Array.new
    htiddlers.each_value do |tiddler|
      unless (tiddler.immediate?)
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
      end
      self_tag << tiddler.title if tiddler.tags.include?(tiddler.title)
    end
    missing_tag.delete(head_tiddler.title)
    missing_tag = missing_tag.sort{|a, b| a.casecmp(b)}
    # linking_imm: tiddlers with an immediate tiddler in the sequential reading
    # tagging_imm: tiddlers tagging an immediate tiddler
    self_tag = self_tag.sort{|a, b| a.casecmp(b)}
    #p missing_tag
    return not_there, repeated, linking_imm, unknowns, missing_tag, self_tag, head_tiddler
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
      wiki << @contents.chomp << "\n\n"
    else
      seqread = International.instance.sequential_reading
      regexp = Regexp.new('.*(?=\n+== ' + Regexp.escape(seqread) + ' ==\n)', Regexp::MULTILINE)
      wiki << @contents[regexp].chomp << "\n\n"
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
	seqread = International.instance.sequential_reading
	regexp = Regexp.new('.*(?=\n+== ' + Regexp.escape(seqread) + ' ==\n)', Regexp::MULTILINE)
	dest.puts @contents[regexp]
	@siblings.each do |title|
	  list << "\n" << htiddlers[title].write_wiki_files(rep, htiddlers)
	end
      end
    end
    list
  end

  def docbook(htiddlers, intro_data, language, init = false)
    sep = "\n"
    inside = ''
    inside = init_docbook(language, intro_data) if init
    inside << @docbook_begin
    unless @siblings.nil? || @siblings.size == 0
      sep = ''
      @siblings.each do |title|
	inside << htiddlers[title].docbook(htiddlers, intro_data, language)
      end
    end
    inside << sep << @docbook_end
    if init
      inside << finish_docbook 
      inside.gsub!(/<para>\s*<\/para>\s*/, '').
	gsub!(/<legalnotice>\s*<\/legalnotice>\s*/, '')
    end
    inside
  end

  def init_docbook(language, intro_data)
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
    included_entities = Entities.instance.included_entities
    entities_data = ''
    if included_entities.count > 0
      entities_data = "<!DOCTYPE book [\n"
      included_entities.each do |key, value|
        entities_data << "<!ENTITY #{key} \"&\##{value};\">\n"
      end
      entities_data << "]>\n"
    end
    #puts "entities_data=#{entities_data}"
    '<?xml version="1.0" encoding="utf-8"?>' << "\n" << entities_data <<
    "<book xml:lang=\"#{language}\"\n" <<
    '     xmlns="http://docbook.org/ns/docbook" version="5.0"' << "\n" <<
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
