#!/usr/bin/perl -w
# extract contents from tiddlywiki classic file into Ruby code.
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

use Switch 'Perl5', 'Perl6';
use String::Util 'trim';

sub browse_wiki {
  my $name = shift;
  $FENT="";
  open(FENT, $name) or die("cannot open $name for reading: $!\n");
  @lignes = <FENT>;
  close(FENT);
  my $step = 0;
  my $title = '';
  my $body = '';
  LIRE: for ($k = 0; $k < @lignes; $k++) {
    $line = $lignes[$k];
    chomp($line);
    #print "#READ \@$step : $line\n" unless $step == 0;
    given ($step) {
      when(0) { $step = 1 if ($line =~ /^<div id="storeArea">$/); }
      when(1) {
	if ($line =~ /^<\/div>$/) {
	  #print "#END OF TIDDLERS AWAITED\n";
	  $step = 10;
	} else {
	  $title = $line;
	  $title =~ s/^.* title="//;
	  $title =~ s/".*$//;
	  my $tags = '';
	  if ($line =~ / tags="/) {
	    $tags = $line;
	    $tags =~ s/^.* tags="//;
	    $tags =~ s/".*$//;
	  }
	  #print "#GOT $title TAGGING $tags\n";
	  $tiddlers{$title} = { 'tags' => $tags, 'raw' => '' };
	  $body = '';
	  $step = 2;
	}
      }
      when(2) {
	$line =~ s/^<pre>//;
	if ($line =~ /<\/pre>$/) {
	  $line =~ s/<\/pre>$//;
	  $tiddlers{$title}{'raw'} = $line;
	  $step = 10;
	  #print "#SINGLE $line\n";
	} else {
	  $body = $line;
	  $step = 3;
	  #print "#YET $line\n";
	}
      }
      when(3) {
	if ($line =~ /<\/pre>$/) {
	  $line =~ s/<\/pre>$//;
	  $body .= "\n" . $line;
	  $tiddlers{$title}{'raw'} = $body;
	  $step = 10;
	  #print "#FINALLY $line\n";
	  #print "#FOR $title FULL $body\n";
	} else {
	  $body .= "\n" . $line;
	  #print "#MORE $line\n";
	}
      }
      when(10) {
	$step = 1 if ($line =~ /^<\/div>$/);
      }
      when(20) {
	last LIRE if ($line =~ /^<!--POST-STOREAREA-->$/);
      }
    }
  }
}

sub ruby {
  print "# encoding: utf-8\n";
  print "def wiki\n  htid = {\n";
  my $tiddler;
  my $defaut = '';
  my $site_title = '';
  my $site_subtitle = '';
  while (($title, $tiddler) = each(%tiddlers)) {
    my %tid = %$tiddler;
    given ($title) {
      when ('SiteTitle') {
	$site_title = $tid{raw};
	chomp($site_title);
      }
      when('SiteSubtitle') {
	$site_subtitle = $tid{raw};
	chomp($site_subtitle);
      }
      when('DefaultTiddlers') {
	$defaut = $tid{raw};
	$defaut =~ s/^(?:\[\[)?([^\]\[]*)(?:\]\])?.*/$1/;
	$defaut =~ s/\n.*//m;
      }
      when ('MainMenu') {
	# nothing
      }
      when ('GettingStarted') {
	# nothing
      }
      else {
	$tags = categorize($tid{tags});
	my $body = $tid{raw};
	$body =~ s/\n/\\n/g;
	print "  \"$title\" => Tiddler.new(\"$title\", $tags,  \"$body\"),\n\n";
      }
    }
  }
  print "  }\n  htid.default = htid['$defaut']\n";
  print "  st = \"$site_title\"\n  sst = \"$site_subtitle\"\n";
  print "  return htid, st, sst\nend\n";
}

sub browse {
  $str = shift;
  $str = trim($str);
  $position = index($str, ' ');
  return $str unless $position >= 0;
  $token = substr($str, 0, $position);
  $str = trim(substr($str, $position + 1));
  if ($token =~ /[[]{2}/) {
    if (index($token, ']]') > 0) {
      $token = substr($token, 2, length($token) - 4);
      return $token . '|' . browse($str);
    }
    $token = substr($token, 2);
    $position = index($str, ']]');
    if ($position < 0) {
      return $token . $str;
    }
    $token .= ' ' . substr($str, 0, $position);
    $str = trim(substr($str, $position + 2));
    return $token . '|' . browse($str);
  }
  return $token . '|' . browse($str);
}

sub categorize {
  $categories = shift;
  $categ = browse($categories);
  $categ =~ s/\|$//;
  @tokens = split(/\|/, $categ);
  $liste = '[ ';
  foreach(@tokens) {
    $liste .= "\"$_\",";
  }
  return substr($liste, 0, length($liste) - 1) . ']';
}

my %tiddlers = ();
$name = $ARGV[0] // 'wiki.html';
browse_wiki($name);
ruby;
