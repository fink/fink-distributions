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
use Fink::Services qw(&latest_version);
use Fink::Package;
use Fink::PkgVersion;
use Fink::Depends2;

use strict;
use warnings;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION = 1.00;
  @ISA         = qw(Exporter Fink::Base);
  @EXPORT      = qw();
  @EXPORT_OK   = qw(&run_dependscheck);
  %EXPORT_TAGS = ( );
}
our @EXPORT_OK;
our %SHLIBS;

# this is the one and only version number
our $depends_version = "0.3.0.cvs";

END { }       # module clean-up code here (global destructor)

### return depends version

sub depends_version {
  return $depends_version;
}

sub run_dependscheck {
  my $self = shift;
  my $pkgname = shift;
  if ($pkgname eq "index") {
    Fink::Depends2->require_shlibs();
    exit 0;
  }
  my (@depends, $depend);
  my ($pkgversion);

  unless (defined $pkgname) {
    print "NOP\n";
    return;
  } 

  unless (check_installed($pkgname)) {
    print "Package \"$pkgname\" NOT installed\n";
    exit 1;
  }

  print "Scanning ${pkgname} for a list of lib depends\n\n";
  @depends = &check_pkg($pkgname);

  foreach $depend (@depends) {
    $SHLIBS{$depend} = 1;
  }

  if (keys %SHLIBS) {
    print "Shared Libs: ".join(', ', sort keys %SHLIBS)."\n\n";
  } else {
    print "Has no shlibs depends!\n\n";
  }

  return;
}

### Check if pkg is installed
sub check_installed {
  my $pattern = shift;
  my (@allnames, @selected, $pname, $package, $lversion, $vo);

  Fink::Package->require_packages();
  @allnames = Fink::Package->list_packages();
  @selected = ();
  $pattern = lc quotemeta $pattern;
  push @selected, grep(/^$pattern$/, @allnames);
  foreach $pname (sort @selected) {
    $package = Fink::Package->package_by_name($pname);
    unless ($package->is_virtual()) {
      $lversion = &latest_version($package->list_versions());
      $vo = $package->get_version($lversion);
      if ($vo->is_installed()) {
        return 1;
      }
    }
  }

  return 0;
}

### Get Depend from shlibs db
sub get_shlibs_dep {
  my $pattern = shift;
  my $dep;

  $dep = Fink::Depends2->get_shlib($pattern);

  return $dep;
}


sub check_pkg {
  my $pkgname = shift;
  my (@depends, $depend, @files, $file, $vers, $deb);

  # get files to test
  open(DPKG, "dpkg --listfiles $pkgname 2>/dev/null |") or die "can't run dpkg: $!\n";
  # iterate through the output of dpkg, looking for bins and libs
  while (<DPKG>) {
    chomp();
    next if (-d "$_");			# Drop  directories
    push(@files, $_);			# all other files get checked
  }
  close (DPKG);

  # get a list of linked files to the pkg files
  foreach $file (@files) {
    chomp($file);
    open(OTOOL, "otool -L $file 2>/dev/null |") or die "can't run otool: $!\n";
      # need to drop all links to system libs and the first two lines
      while (<OTOOL>) {
        chomp();
        next if ("$_" =~ /\:/);			# Nuke first line and errors
        if ($_ =~ /compatibility version ([.0-9]+)/) {
          $vers = $1;
        }
        $_ =~ s/\ \(.*$//;			# Nuke the end
        $_ =~ s/^[\s|\t]+//;
        $_ =~ s/[\s|\t]+$//;
        $deb = "";
        if (length($_) > 1) {
          $deb = Fink::Depends2->get_shlib($_);
          if (length($deb) > 1) {
            push(@depends, $deb);
          } else {
            push(@depends, "$_ (>= $vers)");
          }
        }
      }
    close (OTOOL);
  }
 
  return @depends;
}
