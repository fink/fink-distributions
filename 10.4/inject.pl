#!/usr/bin/perl -w
#
# inject.pl - perl script to copy package definitions into an existing
#             Fink installation
#
# Fink - a package manager that downloads source and installs it
# Copyright (c) 2001 Christoph Pfisterer
# Copyright (c) 2001-2008 The Fink Package Manager Team
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
# Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA 02110, USA.
#

$| = 1;
use 5.006;  # perl 5.6.0 or newer required
use strict;

### We first test the version of fink and upgrade if necessary

BEGIN {

### If we are bootstrapping, init.(c)sh has not been run yet so we need
### to add a path to @INC

    BEGIN {
	my $basepath = $ARGV[0];
	if (defined $basepath) {
	    unshift (@INC, "$basepath/lib/perl5");
	}
    }

use Fink::FinkVersion qw(&fink_version);
use Fink::Services qw(&execute);

### determine the fink version; upgrade it if its too old, otherwise execute
### update.pl

my $fink_version = &fink_version;

if ($fink_version lt "0.21.0") {

    my $basepath = $ARGV[0];

    if (not defined $basepath) {
	die "Please either execute this script with a parameter, or first update to fink 0.21.0 or later.";
    }

### re-execute as root

if ($> != 0) {
  exit &execute("sudo ./inject.pl @ARGV");
}
umask oct("022");

### copy description files for the fink package

print "Copying fink...\n";

if (-f "stable/main/finkinfo/base/fink.info") {
    &execute("/bin/cp -f stable/main/finkinfo/base/fink.info $basepath/fink/dists/stable/main/finkinfo/base; /bin/chmod 644 $basepath/fink/dists/stable/main/finkinfo/base/fink.info");
}

if (-f "stable/main/finkinfo/base/fink.patch") {
    &execute("/bin/cp -f stable/main/finkinfo/base/fink.patch $basepath/fink/dists/stable/main/finkinfo/base; /bin/chmod 644 $basepath/fink/dists/stable/main/finkinfo/base/fink.patch");
}

&execute("fink index; fink update fink");

#exit &execute("./inject.pl $basepath @ARGV");
exit &execute("./inject.pl @ARGV");

}
}

use File::Find;
use Fink::CLI qw(&print_breaking &prompt_boolean);
use Fink::FinkVersion qw(&fink_version);
use Fink::Command qw(cat);

### determine the fink version; bail out if its too old

my $fink_version = &fink_version;

if ($fink_version lt "0.21.0") {
    &print_breaking("\nERROR: old package manager.  Please install a more recent version of fink (at least 0.21.0) before running this script.\n\n");
    exit 1;
}

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
    if (not -d "$filename/main/finkinfo") {
	print "ERROR: Package is incomplete.\n";
	exit 1;
    }
}

### import functions from the bootstrap module (not available in old finks)

require Fink::Bootstrap;
import Fink::Bootstrap qw(&locate_Fink &find_rootmethod);

### locate Fink installation

my $param = shift;

my ($notlocated, $basepath) = &locate_Fink($param);

if ($notlocated) {
    exit 1;
}

# can't use Fink::Bootstrap::find_rootmethod because the optional arguments
# are not passed

#### parse config file for root method
#
#&find_rootmethod($basepath);

### re-execute as root                                                          
unshift(@ARGV, $basepath);

if ($> != 0) {
    exit &execute("sudo ./inject.pl @ARGV");
}
umask oct("022");


### determine the distribution

use Fink::Config;
my $config = Fink::Config->new_with_path("$basepath/etc/fink.conf");
#import Fink::Config qw($distribution);

my $distribution = $config->param("Distribution");

#&print_breaking("The distribution is $distribution.\n");

### where do we install?

my $dists;
if (-f "DISTRIBUTION") {
    chomp($dists = cat "DISTRIBUTION");
} else {
die "The file \'DISTRIBUTION\' is missing from this directory.\n"
}

if (not $distribution eq $dists) {
    my $answer = &prompt_boolean("\nVERSION MISMATCH: the packages in this directory are intended for the $dists distribution, but you are running under the $distribution distribution.  A mismatched installation like this might be useful for Fink developers, but is unlikely to be useful for most Fink users.  Do you wish to continue?",0);
    if (not $answer) {
	die "\nExiting without installing any packages.\n\n";
    }
}

### make sure our directories exist

&execute("/bin/mkdir -p -m755 $basepath/fink/$dists");

### is the existing system set up for CVS?

foreach $filename (@directories) {
    if (-d "$basepath/fink/CVS" or -d "$basepath/fink/$dists/CVS" or -d "$basepath/fink/$dists/$filename/CVS") {
  &print_breaking("The directory '$basepath' contains a Fink installation ".
		  "that was set up to get package descriptions directly ".
		  "from CVS. This script will not update this ".
		  "installation. Run 'cvs update -d -P' in the directory ".
		  "'$basepath/fink/$dists' instead.");
  exit 1;
}
}

### copy description files

print "Copying...\n";

if (not -d "$basepath/fink/debs") {
  &execute("/bin/mkdir -p -m755 $basepath/fink/debs");
}

if (&execute("/bin/cp -f README $basepath/fink/$dists/; /bin/chmod 644 $basepath/fink/$dists/README")) {
  print "ERROR: Can't copy README file.\n";
  exit 1;
}

if (&execute("/bin/cp -f VERSION $basepath/fink/$dists/; /bin/chmod 644 $basepath/fink/$dists/VERSION")) {
  print "ERROR: Can't copy VERSION file.\n";
  exit 1;
}

if (&execute("/bin/cp -f DISTRIBUTION $basepath/fink/$dists/; /bin/chmod 644 $basepath/fink/$dists/DISTRIBUTION")) {
  print "ERROR: Can't copy DISTRIBUTION file.\n";
  exit 1;
}

&execute("rm -f $basepath/fink/$dists/stamp-*");
if (-f "stamp-cvs-live") {
  my @now = gmtime(time);
  my $timestamp = sprintf("%04d%02d%02d-%02d%02d",
			  $now[5]+1900, $now[4]+1, $now[3],
			  $now[2], $now[1]);
  &execute("touch $basepath/fink/$dists/stamp-cvs-$timestamp");
} else {
  &execute("cp stamp-* $basepath/fink/$dists/");
}

sub wanted {
  my ($dir);
  if (-f and not /^[\.#]/ and (/\.info$/ or /\.patch$/)) {
    $dir = $basepath."/fink/$dists/".$File::Find::dir;
    if (not -d $dir) {
      if (&execute("/bin/mkdir -p -m755 $dir")) {
	print "ERROR: Can't copy package descriptions.\n";
	exit 1;
      }
    }
    if (&execute("/bin/cp -f $_ $dir/; /bin/chmod 644 $dir/$_")) {
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


### eof
exit 0;
