#!/usr/bin/ruby -Ku
# use information from generated ruby file to create a docbook v5.
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

require 'date'
require 'optparse'
require 'ostruct'

require_relative 'tiddler'

class Array
  def do_list(sep)
    case count 
    when 0 then ''
    when 1 then fetch(0).to_s << sep
    else slice(1, length).do_list(', ') << fetch(0).to_s << sep
    end
  end
  protected :do_list

  def list
    reverse.do_list('')
  end
    
  def quote_list
    map { |item| "\"#{item}\"" }.list
  end
    
end

class SupportedOptionParse
  def self.parse(args)
    # The options specified on the command line will be collected in *options*.
    # We set default values here.
    options = OpenStruct.new
    options.job_type = nil
    options.language = ''
    options.extension = 'project.rb'
    options.filename = 'project.xml'
    options.dirname = 'project'

    got_options = OptionParser.new do |opts|
      opts.banner = 'Usage: wiki2docbook.rb [options]'

      opts.separator ''
      opts.separator 'Specific options:'

      opts.on('-c', '--check',
	      'check for wikis images') do
	options.job_type = :images_check
      end

      opts.on('-d', '--docbook FILENAME', String,
	      'generate docbook XML file') do |filename|
	options.job_type = :docbook
	options.filename = filename
      end

      opts.on('-s', '--single FILENAME', String,
	      'generate single file mediawiki') do |filename|
	options.job_type = :single_wiki
	options.filename = filename
      end

      opts.on('-m', '--multi DIRECTORYNAME', String,
	      'generate mulitple files mediawiki') do |dirname|
	options.job_type = :multi_wiki
	options.dirname = dirmame
      end

      opts.on('-e', '--extension EXTENSION_RUBY_FILE', String,
	      'ruby extension file got from original wiki file') do |extension|
	options.extension = extension
      end
      # used language
      opts.on("-l", "--language LANGUAGE",
	      "Specify which LANGUAGE to use") do |lang|
	options.language = lang
      end

      # No argument, shows at tail.  This will print an options summary.
      # Try it and see!
      opts.on_tail("-h", "--help", "Show this message") do
	puts opts
	exit 1
      end
    end

    got_options.parse!(args)
    options
  end  # parse()
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

# report errors detected during standard analyse of the tiddlers set
#
# @param tiddlers: all the tiddlers
# @param language: abbreviation of the language (for sequential readind L12n)
# @return head: root tiddler
def report_errors(tiddlers, language)
  International.instance.setup(language)
  oprhans = Tiddler.analyze_links(tiddlers)
  if oprhans.size > 0
    oprhans.each { |ref, tiddlers|
      msg = "Error: orphan link \"#{ref}\" in "
      if tiddlers.size == 1
        msg << '"' << tiddlers[0] << '".'
      else
        msg << "#{tiddlers.size} tiddlers:\n"
        tiddlers.each { |tiddler| msg << "  * \"#{tiddler}\";\n" }
        msg[-2] = '.'
      end
      puts msg
    }
    puts 'Orphan Link Error'
    exit 1
  end
  not_tagged, nonexistent_tags, bad_tag = Tiddler.analyze_tags(tiddlers)
  if not_tagged.size > 0
    not_tagged.each { |title|
      print "Error: tiddler without real tag: \"#{title}\"\n"
    }
  end
  if bad_tag.size > 0
    bad_tag.each_key do |tag|
      puts "Error: unknown format tag \"#{tag}\" occurs in the following tiddler(s):\n" <<
        bad_tag[tag].quote_list << '.'
    end
  end
  if nonexistent_tags.size > 0
    nonexistent_tags.each_key do |tag|
      puts "Error: tiddler \"#{tag}\" does not exists but is tagged by " <<
        nonexistent_tags[tag].quote_list << '.'
    end
  end
  if bad_tag.size > 0 || nonexistent_tags.size > 0 || not_tagged.size > 0
    puts 'Tagging Error'
    exit 1
  end
  not_included, repeated, linking_imm, unknown, missing_tag,
  self_tag, head = Tiddler.analyze_sequential_reading(tiddlers)
  if (head.nil?)
    puts 'Error: no initial tiddler.'
    exit 1
  end
  tagging_imm = [] # todo: tagging_imm to be computed with htiddlers
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
    puts 'Sequential Reading Error'
    exit 1
  end
  ent_err = Entities.instance.unsupported_entities
  if (ent_err.count > 0)
    print "unsupported entit" << ((ent_err.count == 1) ? 'y' : 'ies') << ':'
    ent_err.each { |ent| print " &#{ent};" }
    puts
    exit 1
  end
  head
end

# extract necessary information from the ruby source transcripting the wiki
#
# @param extension: name of the ruby source to be loaded
# @param language: two letters ISO abbreviation of the language
# @return (tiddlers, site_title, site_subtitle, head):
  # @item tiddlers: hash of all the tiddlers
  # @item site_title: title of the book
  # @item site_subtitle: book subtitle
  # @item head: root tiddler
def extract_info(extension, language)
  puts "loading #{extension}"
  load extension
  tiddlers, site_title, site_subtitle = wiki
  head = report_errors(tiddlers, language)
  return tiddlers, site_title, site_subtitle, head
end

begin
  options = SupportedOptionParse.parse(ARGV)
rescue OptionParser::InvalidOption => ioe
  puts ioe
  SupportedOptionParse.parse(['-h'])
  exit(1)
end
case options.job_type
when :docbook
  tiddlers, site_title, site_subtitle, head = extract_info(options.extension, options.language)
  tiddlers.values.each { |tiddler| tiddler.translate_to_docbook(tiddlers) }
  intro_data = fetch_intro_data(tiddlers, site_title, site_subtitle)
  puts "generating docbook #{options.filename}"
  File.open(options.filename, 'w') do |dbf|
    dbf.print head.docbook(tiddlers, intro_data, options.language, true)
  end
when :single_wiki
  tiddlers, site_title, site_subtitle, head = extract_info(options.extension, options.language)
  File.open(options.filename, 'w') { |dbf| dbf.print head.wiki_single(tiddlers, true) }
when :multi_wiki
  tiddlers, site_title, site_subtitle, head = extract_info(options.extension, options.language)
  repertoire = options.dirname.gsub(/\/+$/, '') << '/'
  puts head.write_wiki_files(repertoire, tiddlers, true)
when :images_check
  tiddlers, site_title, site_subtitle, head = extract_info(options.extension, options.language)
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
  unless options.job_type.nil?
    puts "job #{options.job_type} not supported yet"
  else
    SupportedOptionParse.parse(['-h'])
  end
  exit 1
end
exit 0
