#!/usr/bin/perl -w
# generate makefiles for graphics.
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

use Switch 'Perl5', 'Perl6';

sub prepare_svg {
  my $parentDir = shift;
  my $newParentDir = shift;
  my $dir = shift;
  my $files = shift;
  my $targets = '';
  my $rules = '';
  my %dirs = ();
  my $cmd01 = 'inkscape $< --export-plain-svg=/tmp/svg$$.svg';
  my $cmd02 = 'rsvg-convert -a -w ${WIDTH} -f svg /tmp/svg$$.svg -o $@';
  my $cmd03 = 'rm -f /tmp/svg$$.svg';
  foreach my $inkscape (@$files) {
    my $standard = $inkscape;
    $standard =~ s/\.inkscape\.svg$/.svg/;
    print "working at $standard\n";
    $targets .= "\t$newParentDir/$dir/$standard \\\n";
    $rules .= "$newParentDir/$dir/$standard : $parentDir/$dir/$inkscape\n"
      . "\t$cmd01\n"
      . "\t$cmd02\n"
      . "\t$cmd03\n\n";
  }
  return ($targets, $rules);
}

sub prepare_png {
  my $parentDir = shift;
  my $newParentDir = shift;
  my $dir = shift;
  my $files = shift;
  my $targets = '';
  my $rules = '';
  my %dirs = ();
  my $cmd = 'rsvg-convert -a -w ${WIDTH} -f png -o $@ $<';
  foreach my $inkscape (@$files) {
    my $standard = $inkscape;
    print "working at $standard\n";
    $standard =~ s/(\.inkscape)?\.svg$/.png/;
    $targets .= "\t$newParentDir/$dir/$standard \\\n";
    $rules .= "$newParentDir/$dir/$standard : $parentDir/$dir/$inkscape\n"
      . "\t$cmd\n\n";
  }
  return ($targets, $rules);
}

sub writeMakefile {
  my $width = shift;
  my $dest = shift;
  my $newParentDir = shift;
  my $schemas = shift;
  my $tree = shift;
  my $targets = shift;
  my $rules = shift;
  open(FSOR, ">$dest") or die("cannot create file $dest: $!\n");
  print FSOR "#makefile for $schemas -- auto generated with ./generate-schemas-makefile.pl\n\n";
  print FSOR "WIDTH=$width\n\n";
  print FSOR ".PHONY: ALL\n\n";
  print FSOR "ALL: TREE \\\n$$targets\n\n";
  print FSOR "clean:\n\trm -rf $newParentDir\n\n";
  print FSOR "TREE:\n\t\@mkdir -p \\\n$$tree\n\n$$rules";
  close(FSOR);
}

sub act_svg {
  my $width = shift;
  my $makefile = shift;
  my $schemas = shift;
  my $dirname = "$schemas/figs-inkscape";
  opendir my $dh, $dirname or die "Couldn't open dir '$dirname': $!";
  my @dirs = grep { !/^\./ } readdir $dh;
  closedir $dh;
  my $newParentDir = $dirname;
  $newParentDir =~ s/inkscape$/svg/;
  my $tree = ''; 
  my $targets = '';
  my $rules = '';
  foreach my $dir (@dirs) {
    print "working on $dirname/$dir\n";
    opendir $dh, "$dirname/$dir" or die "couldn't open dir '$dirname/$dir': $!";
    my @files = grep { /\.svg$/ } readdir $dh;
    closedir $dh;
    $tree .= "\t\t$newParentDir/$dir \\\n";
    my ($target, $rule) = prepare_svg($dirname, $newParentDir, $dir, \@files);
    $targets .= $target;
    $rules .= $rule;
  }
  writeMakefile($width, $makefile, $newParentDir, $schemas, \$tree, \$targets, \$rules);
}

sub act_png {
  my $width = shift;
  my $makefile = shift;
  my $schemas = shift;
  my $dirname = "$schemas/figs-inkscape";
  opendir my $dh, $dirname or die "Couldn't open dir '$dirname': $!";
  my @dirs = grep { !/^\./ } readdir $dh;
  closedir $dh;
  my $newParentDir = $dirname;
  $newParentDir =~ s/inkscape$/png/;
  my $tree = ''; 
  my $targets = '';
  my $rules = '';
  foreach my $dir (@dirs) {
    print "working on $dirname/$dir\n";
    opendir $dh, "$dirname/$dir" or die "couldn't open dir '$dirname/$dir': $!";
    my @files = grep { /\.svg$/ } readdir $dh;
    closedir $dh;
    $tree .= "\t\t$newParentDir/$dir \\\n";
    my ($target, $rule) = prepare_png($dirname, $newParentDir, $dir, \@files);
    $targets .= $target;
    $rules .= $rule;
  }
  writeMakefile($width, $makefile, $newParentDir, $schemas, \$tree, \$targets, \$rules);
}

my $typepix = shift;
my $schemas = shift;
my $width = shift; # size given in pt and not in px
my $makefile = shift;
given($typepix) {
  when('svg') { act_svg($width, $makefile, $schemas); }
  when('png') { act_png($width, $makefile, $schemas); }
  else { die "image type $typepix unsupported."; }
}
