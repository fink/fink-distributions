#!/usr/bin/perl -w
#
# inject.pl - perl script to copy package definitions into an existing
#             Fink installation
#
# Fink - a package manager that downloads source and installs it
# Copyright (c) 2001 Christoph Pfisterer
# Copyright (c) 2001-2003 The Fink Package Manager Team
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#

$| = 1;
use v5.6.0;  # perl 5.6.0 or newer required
use strict;

use File::Find;

### list our directories

my @contents = `ls`;
my ($filename,@directories);
foreach $filename (@contents) {
    chomp($filename);
    if (-d $filename and not $filename eq "CVS") {
	push(@directories, $filename);
    }
}
### check if we're unharmed

foreach $filename (@directories) {
    if (not -d "$filename/stable/main/finkinfo") {
	print "ERROR: Package is incomplete.\n";
	exit 1;
    }
}

### locate Fink installation

my ($basepath, $guessed, $param, $path);

$guessed = "";
$param = shift;
if (defined $param) {
  $basepath = $param;
} else {
  $basepath = undef;
  if (exists $ENV{PATH}) {
    foreach $path (split(/:/, $ENV{PATH})) {
      if (substr($path,-1) eq "/") {
	$path = substr($path,0,-1);
      }
      if (-f "$path/init.sh" and -f "$path/fink") {
	$path =~ /^(.+)\/[^\/]+$/;
	$basepath = $1;
	last;
      }
    }
  }
  if (not defined $basepath or $basepath eq "") {
    $basepath = "/sw";
  }
  $guessed = " (guessed)";
}
unless (-f "$basepath/bin/fink" and
	-f "$basepath/bin/init.sh" and
	-f "$basepath/etc/fink.conf" and
	-l "$basepath/fink/dists") {
  &print_breaking("The directory '$basepath'$guessed does not contain a ".
		  "Fink installation. Please provide the correct path ".
		  "as a parameter to this script.");
  exit 1;
}
foreach $filename (@directories) {
    if (-d "$basepath/fink/CVS" or -d "$basepath/fink/$filename/CVS") {
  &print_breaking("The directory '$basepath' contains a Fink installation ".
		  "that was set up to get package descriptions directly ".
		  "from CVS. This script will not update this ".
		  "installation. Run 'cvs update -d -P' in the directory ".
		  "'$basepath/fink' instead.");
  exit 1;
}
}

### parse config file for root method

# TODO: really parse the file, support both su and sudo
# for now, we just use sudo...

if ($> != 0) {
  exit &execute("sudo ./inject.pl $basepath");
}
umask oct("022");

### copy description files

print "Copying...\n";

if (not -d "$basepath/fink/debs") {
  &execute("mkdir -p $basepath/fink/debs");
}

if (&execute("cp -f README $basepath/fink/")) {
  print "ERROR: Can't copy README file.\n";
  exit 1;
}

if (&execute("cp -f VERSION $basepath/fink/")) {
  print "ERROR: Can't copy VERSION file.\n";
  exit 1;
}

&execute("rm -f $basepath/fink/stamp-*");
if (-f "stamp-cvs-live") {
  my @now = gmtime(time);
  my $timestamp = sprintf("%04d%02d%02d-%02d%02d",
			  $now[5]+1900, $now[4]+1, $now[3],
			  $now[2], $now[1]);
  &execute("touch $basepath/fink/stamp-cvs-$timestamp");
} else {
  &execute("cp stamp-* $basepath/fink/");
}

sub wanted {
  my ($dir);
  if (-f and not /^[\.#]/ and (/\.info$/ or /\.patch$/)) {
    $dir = $basepath."/fink/".$File::Find::dir;
    if (not -d $dir) {
      if (&execute("mkdir -p $dir")) {
	print "ERROR: Can't copy package descriptions.\n";
	exit 1;
      }
    }
    if (&execute("cp -f $_ $dir/")) {
      print "ERROR: Can't copy package descriptions.\n";
      exit 1;
    }
  }
}

### this version of the script is for "10.2" and later, not "dists"

  foreach $filename (@directories) {
      find(\&wanted, "$filename");
  }

### inform the user

unless (defined $ARGV[0] and $ARGV[0] eq "-quiet") {
  print "\n";
  &print_breaking("Your Fink installation in '$basepath' was updated with ".
		  "new package description files. Please update the package ".
		  "manager using 'fink update fink', then use appropriate ".
		  "commands to update the other packages, ".
		  "e.g. 'fink update-all'.");
  print "\n";
}


### helper functions

sub execute {
  my $cmd = shift;
  my $quiet = shift || 0;
  my ($retval, $prog);

  print "$cmd\n";
  $retval = system($cmd);
  $retval >>= 8 if defined $retval and $retval >= 256;
  if ($retval and not $quiet) {
    ($prog) = split(/\s+/, $cmd);
    print "### $prog failed, exit code $retval\n";
  }
  return $retval;
}

sub print_breaking {
  my $s = shift;
  my ($pos, $t);
  my $linelength = 77;

  chomp($s);
  while (length($s) > $linelength) {
    $pos = rindex($s," ",$linelength);
    if ($pos < 0) {
      $t = substr($s,0,$linelength);
      $s = substr($s,$linelength);
    } else {
      $t = substr($s,0,$pos);
      $s = substr($s,$pos+1);
    }
    print "$t\n";
  }
  print "$s\n";
}

### eof
exit 0;
