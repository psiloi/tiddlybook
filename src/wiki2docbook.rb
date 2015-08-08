#!/usr/bin/ruby -Ku
# use information from generated ruby file to create a docbook v5.
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

require 'date'

require_relative 'tiddler'

def purpose
  puts "use: wiki2docbook <option> <rubyfied_wiki.rb>\n" +
        "where option = -s <file> (write single file wiki)\n" +
        "or -m <directory> (write multiple files wiki)\n" +
        "or -d <file> (write docbook)\n" +
        "or -c (check images only)"
  exit 2
end

def fetch_intro_data(tiddlers, site_title, site_subtitle)
  vernum = pubdate = legalese = ''
  version = tiddlers['version']
  version = tiddlers['Version'] if version.nil?
  # the most recent version must be the first in the table.
  version.contents.sub(/^\|(\d+\.\d+\.\d+)$/) { |number| vernum = $1 }
  version.contents.sub(/^\|(\d+\/\d+\/\d+)$/) { |date| pubdate = $1 }
  authors = []
  if (tiddlers.count > 0)
    ok_license = ok_authors = false
    tiddlers[0].contents.each_line do |line|
      if (ok_license)
	# legalese mus be text only. It may have to be more gsub here...
        legalese = line.sub(/^: */, '').gsub(/'{2,}/, '').
	  gsub(/\[\S+\s+([^\]]+)\]/, '\1')
        ok_license = false
      elsif (ok_authors)
        if (line =~ /^:/)
          line = line.sub(/^: */, '')
          author = line.split(/'''/)
          authors << {
            'firstname' => author[0].strip,
            'surname' => author[1].strip,
            'email' => author[2].strip.sub(/ *[(]at[)] */, '@')
          }
        else
          ok_authors = false
        end
      else
	#puts "line #{line}"
        ok_license = (line =~ /; *[Ll]icense\b/)
        ok_authors = (line =~ /; *[Aa]uthors?\b/)
      end
    end
  end
  intro_data = {
    'title' => site_title,
    'subtitle' => site_subtitle,
    'authors' => authors,
    'version' => vernum,
    'pubdate' => pubdate,
    'legalese' => legalese
  }
  intro_data
end

purpose if ARGV.count < 2
extension = ARGV[ARGV.count - 1]
load extension
tiddlers, site_title, site_subtitle = wiki
not_tagged, nonexistent_tags, bad_tag = Tiddler.analyze_tags(tiddlers)
if not_tagged.size > 0
  not_tagged.each { |title|
    print "Error: tiddler without real tag: \"#{title}\"\n"
  }
end
if bad_tag.size > 0
  bad_tag.each_key { |tag|
    print "Error: unknown format tag \"#{tag}\" occurs in the following tiddler(s):\n"
    sep = ''
    bad_tag[tag].each { |title| print sep << title; sep = ', ' }
    puts
  }
end
if nonexistent_tags.size > 0
  nonexistent_tags.each { |title|
    print "Error: tiddler \"#{title}\" does not exists but is tagged.\n"
  }
end
if bad_tag.size > 0 || nonexistent_tags.size > 0 || not_tagged.size > 0
  print "Tagging Error\n"
  exit 1
end
not_included, repeated, linking_imm, unknown, missing_tag,
  self_tag, head = Tiddler.analyze_sequential_reading(tiddlers)
if (head == nil)
  print "Error: no initial tiddler\n"
  exit 1
end
tagging_imm = [] # a calculer via htiddlers mais pas encore fait
if (not_included.size != 0 || repeated.size != 0 || linking_imm.size != 0 ||
  tagging_imm.size != 0 || unknown.size != 0 || missing_tag.size != 0 ||
  self_tag.size != 0)
  #print "----------\n"
  not_included.each { |title| print "Not Included Error: \"#{title}\".\n" }
  repeated.each { |msg| print msg }
  linking_imm.each { |msg| print msg }
  tagging_imm.each { |msg| print msg }
  unknown.each { |msg| print msg }
  missing_tag.each { |title| print "Missing Parent Tag Error: \"#{title}\".\n" }
  self_tag.each { |title| print "Tagging Itself Error: \"#{title}\".\n" }
  print "Sequential Reading Error\n"
  exit 1
end
tiddlers.values.each { |tiddler| tiddler.translate_to_docbook(tiddlers) }
option = ARGV[0]
case option
when "-d"
  purpose if ARGV.count != 3
  intro_data = fetch_intro_data(tiddlers, site_title, site_subtitle)
  File.open(ARGV[1], 'w') { |dbf| dbf.print head.docbook(tiddlers, intro_data, true) }
when "-s"
  purpose if ARGV.count != 3
  File.open(ARGV[1], 'w') { |dbf| dbf.print head.wiki_single(tiddlers, true) }
when "-m"
  purpose if ARGV.count != 3
  repertoire = ARGV[1].gsub(/\/+$/, '') << '/'
  puts head.write_wiki_files(repertoire, tiddlers, true)
when "-c"
  purpose if ARGV.count != 2
  no_picture, no_title, no_file = Tiddler.analyse_pictures(tiddlers)
  if no_picture.size != 0 || no_title.size != 0 || no_file.size != 0
    #print "----------\n"
    no_picture.each { |msg| print msg }
    no_title.each { |msg| print msg }
    no_file.each { |msg| print msg }
    print "Picture Description Error\n"
    exit 1 if no_picture.size != 0 || no_title.size != 0
  end
else
  purpose
end
exit 0
