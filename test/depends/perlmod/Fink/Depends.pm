#
# Fink::Depends class
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

package Fink::Depends;
use Fink::Base;
use Fink::Config qw($basepath);

use strict;
use warnings;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION = 1.00;
  @ISA         = qw(Exporter Fink::Base);
  @EXPORT      = qw();
  @EXPORT_OK   = qw(&depends_version &run_dependscheck);
  %EXPORT_TAGS = ( );
}
our @EXPORT_OK;
our %PACKAGES;

# this is the one and only version number
our $depends_version = "0.1.0.cvs";

END { }       # module clean-up code here (global destructor)

### return depends version

sub depends_version {
  return $depends_version;
}

sub run_dependscheck {
  my $self = shift;
  my $pkgname = shift;
  my (@depends, $depend);

  unless (defined $pkgname) {
    print "NOP\n";
    return;
  } 

  print "Scanning ${pkgname} for a list of lib depends\n";
  @depends = &check_pkg($pkgname);

  foreach $depend (@depends) {
    chomp($depend);
    $PACKAGES{$depend} = 1;  
  }

  if (keys %PACKAGES) {    
    print "\nDepends: ", join(', ', sort keys %PACKAGES), "\n\n";
  } else {
    print "\nHas no lib depends!\n\n";
  }

  return;
}

sub check_pkg {
  my $pkgname = shift;
  my (@depends, $depend, @files, $file, @matches, $match);

  # get files to test
  open(DPKG, "dpkg --listfiles $pkgname 2>/dev/null |") or die "can't run dpkg: $!\n";
  # iterate through the output of dpkg, looking for bins and libs
  while (<DPKG>) {
    chomp();
    next if (-d "$_");			# Drop  directories
    if ("$_" =~ /\.dylib/) {		# Check for (.dylib) libs
      push(@files, $_);
    } elsif ("$_" =~ /\.a/) {		# Check for (.a) libs
      push(@files, $_);
    } elsif ("$_" =~ /\.so/) {		# Check for (.so) libs
      push(@files, $_);
    } elsif ("$_" =~ /\/bin\//) {	# Check for anything in %p/bin
      push(@files, $_);
    } elsif ("$_" =~ /\/sbin\//) {	# Check for anything in %p/sbin
      push(@files, $_);
    } else {				# Drop everything else
      next;
    }
  }
  close (DPKG);

  # get a list of linked files to the pkg files
  foreach $file (@files) {
    chomp($file);
    open(OTOOL, "otool -L $file 2>/dev/null |") or die "can't run otool: $!\n";
      # need to drop all links to system libs and the first two lines
      while (<OTOOL>) {
        chomp();
        next if ("$_" =~ /\:/);		# Nuke first line or errors
        next if ("$_" =~ /\/usr\/lib\/libSystem/);	# Nuke system links
        $_ =~ s/\ \(.*$//;		# Nuke the end
        push(@matches, $_);
      }
    close (OTOOL);
   }

   # get list of depend pkgs
   foreach $match (@matches) {
    if (length($match) > 1) {
      $depend = `dpkg --search $match`;
      $depend =~ s/\:.*$//;		# strip out everything after the colon
      chomp($depend);
      next if ($depend eq $pkgname);	# Can't dpend on it's self
      push(@depends, $depend);
    }
  }
 
  return @depends;
}
