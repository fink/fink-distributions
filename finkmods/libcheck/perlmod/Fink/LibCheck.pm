#
# Fink::LibCheck class
#
# Fink - a package manager that downloads source and installs it
# Copyright (c) 2001 Christoph Pfisterer
# Copyright (c) 2001-2002 The Fink Package Manager Team
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

$|++;

package Fink::LibCheck;
use Fink::Base;
use Fink::Config qw($basepath);
use Fink::Services qw(&prompt_boolean);
use Fink::Config qw(&get_option &verbosity_level);

use strict;
use warnings;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION = 1.00;
  @ISA         = qw(Exporter Fink::Base);
  @EXPORT      = qw();
  @EXPORT_OK   = qw(&libcheck_version &run_libcheck);
  %EXPORT_TAGS = ( );
}
our @EXPORT_OK;
our @SCANLIST; # list of directories to search
our %PACKAGES;  # list of packages

# this is the one and only version number
our $libcheck_version = "0.1.1.cvs";

END { }       # module clean-up code here (global destructor)

### return libcheck version

sub libcheck_version {
  return $libcheck_version;
}

sub run_libcheck {
  my $self = shift;
  my $exclude;
  if (&get_option("exclude") == 0) {
    $exclude = "0";
  } else {
    $exclude = shift;
  }
  my $libname = shift;

  unless (defined $libname) {
    print "NOP\n";
    return;
  } 

  print "Scanning ${basepath} for files linked against ${libname}";
  if ( $exclude eq "0") {
    print "\n";
  } else {
    print " but not ${exclude}\n";
  }
  &check_dirs($libname, $exclude);
}

sub has_library {
  my $library    = shift;
  my $search_for = shift;
  my $exclude = shift;

  my @matches;

  open(OTOOL, "otool -L $library 2>/dev/null |") or die "can't run otool: $!\n";
  # iterate through the output of otool, looking for matches
  while (<OTOOL>) {
    chomp();
    if (/$search_for/) {
      if ($exclude eq "0") {
        s/^\s*//;
        push(@matches, $_);
      } else {
        # Need to implement exclude here
        print "$library has $search_for and $exclude\n";
        if (&verbosity_level() == 3) {
          print `otool -L $library | grep \"$search_for\"` . "\n"; 
        }
      }
    }
  }
  close(OTOOL);
  return @matches;
}

sub check_dirs {
  my $libname = shift;
  my $exclude = shift;
  my ($file, $dir, $checkcmd, $where);
  my (@filelist);
  my ($fullpkglist, $install);

  for ("bin", "sbin", "lib") {
    # find all subdirectories, populates @SCANLIST
    for my $directory (split(/[\r\n]+/, `find $basepath/$_ -type d 2>/dev/null`)) {
      push(@SCANLIST, $directory);
    }
  }

  foreach my $dir (@SCANLIST) {
    print "Scanning $dir...\n";

    # this gets everything in a directory that's not . or ..
    opendir(DIR, "$dir") or die "can't open $dir: $!\n";
    for my $file (grep(!/^\.\.?$/, readdir(DIR))) {
      next if (-d "$dir/$file"); # skip directories
      chomp($file);
      $file = "$dir/$file";
      if (has_library($file, $libname, $exclude)) {
        my $package = `dpkg --search $file`;
	$package =~ s/\:.*$//; # strip out everything after the colon
        chomp($package);
        print "- found in $package ($file)\n";
        if (&verbosity_level() == 3) {
          print `otool -L $file | grep \"$libname\"` . "\n";
        }
        $PACKAGES{$package} = 1;
      }
    }
    closedir(DIR);

  }

  if (keys %PACKAGES) {
    print "\nIf you were scanning for an out of date lib, these packages ".
          "were linked against it and may need to be rebuilt: ", join(', ', sort keys %PACKAGES), "\n\n";
    if (&get_option("dontask") ne "0") {
      $install = 1;
    } else {
      $install = &prompt_boolean("Do you want to rebuild this list of".
                                 " packages?", 0);
    }

    if ($install == 1) {
      `fink rebuild $fullpkglist`;
    }
  }

  print "done.\n";

  return;
}
