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
use Fink::Shlibs;

use strict;
use warnings;

BEGIN {
  use Exporter ();
  our ($VERSION, @ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
  $VERSION = 1.00;
  @ISA         = qw(Exporter Fink::Base);
  @EXPORT      = qw();
  @EXPORT_OK   = qw(&show_shlibs &show_versions &depends_version &run_dependscheck);
  %EXPORT_TAGS = ( );
}
our @EXPORT_OK;
our %PACKAGES;
our %SHLIBS;

# this is the one and only version number
our $depends_version = "0.3.0.cvs";
our $show_versions = "false";
our $show_shlibs = "false";

END { }       # module clean-up code here (global destructor)

### return depends version

sub depends_version {
  return $depends_version;
}

sub show_versions {
  $show_versions = "true";
  return;
}

sub show_shlibs {
  $show_shlibs = "true";
  return;
}

sub run_dependscheck {
  my $self = shift;
  my $pkgname = shift;
  if ($pkgname eq "index") {
    Fink::Shlibs->require_shlibs();
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
    chomp($depend);
    if ($depend =~ /shlibs$/) {
      $pkgversion = get_shlibsversion($depend);
      $depend = $pkgversion;
      $SHLIBS{$depend} = 1;
    } elsif ($depend =~ /^\/usr/ || $depend =~ /^\/System/) {
      $SHLIBS{$depend} = 1;
    } else {
    if ($show_versions eq "true") {
        $pkgversion = get_dependversion($depend);
        $pkgversion = "(>= $pkgversion)";
        $depend = "$depend $pkgversion";
        $PACKAGES{$depend} = 1;
      } else {
        $PACKAGES{$depend} = 1;
      }
    }
  }

  if ($show_shlibs eq "true") {
    if (keys %SHLIBS) {
      print "Shared Libs: ", join(', ', sort keys %SHLIBS), "\n\n";
    } else {
      print "Has no shlibs depends!\n\n";
    }
  }
  if (keys %PACKAGES || keys %SHLIBS) {    
    print "Depends: ";
    if (keys %SHLIBS) {
      print "\${SHLIB_DEPS}";
    }
    if (keys %SHLIBS && keys %PACKAGES) {
      print ", ";
    }
    if (keys %PACKAGES) {
      print join(', ', sort keys %PACKAGES);
    }
    print "\n\n";
  } else {
    print "Has no lib depends!\n\n";
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

### Get Depend version
sub get_dependversion {
  my $pattern = shift;
  my ($vo, $lversion, @allnames, @selected, $pname, $package);

  Fink::Package->require_packages();
  @allnames = Fink::Package->list_packages();
  @selected = ();
  $pattern = lc quotemeta $pattern;
  push @selected, grep(/^$pattern$/, @allnames);
  foreach $pname (sort @selected) {
    $package = Fink::Package->package_by_name($pname);
    $lversion = &latest_version($package->list_versions());
  }

  return $lversion;
}

### Get Depend version from shlibs field
sub get_shlibsversion {
  my $pattern = shift;
  my ($vo, $lversion, @allnames, @selected, $pname, $package);
  my ($shlib, $sdepend, @shlibs);

  Fink::Package->require_packages();
  @allnames = Fink::Package->list_packages();
  @selected = ();
  $pattern = lc quotemeta $pattern;
  push @selected, grep(/^$pattern$/, @allnames);
  foreach $pname (sort @selected) {
    $package = Fink::Package->package_by_name($pname);
    $lversion = &latest_version($package->list_versions());
    $vo = $package->get_version($lversion);
  }

  if ($vo->has_param("shlibs")) {
    @shlibs = split(/\n/, $vo->param("shlibs"));
    foreach $shlib (@shlibs) {
      ### FIXME not a perfect check, need to be more specific
      if (($shlib =~ / $pattern /m || $shlib =~ / %n /m) && $shlib =~ /^.+ [.0-9]+ (.*)$/) {
        $sdepend = $1;
        $sdepend =~ s/%n/$pattern/mg;
        $sdepend =~ s/%N/$pattern/mg;
        $sdepend =~ s/\\//mg;
      }
    }
  }

  return $sdepend;
}


sub check_pkg {
  my $pkgname = shift;
  my (@depends, $depend, @files, $file, @matches, $match, $vers);

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
        if ("$_" =~ /\/usr\/lib\// || "$_" =~ /\/System\/Library/) {
          if ($_ =~ /compatibility version ([.0-9]+)/) {
            $vers = $1;
          }
          $_ =~ s/\ \(.*$//;			# Nuke the end
          $_ = $_." (>= ".$vers.")";
          $_ =~ s/^[\s|\t]+//;
          $_ =~ s/[\s|\t]+$//;
          push(@depends, $_);
        }
        $_ =~ s/\ \(.*$//;			# Nuke the end
        $_ =~ s/^[\s|\t]+//;
        $_ =~ s/[\s|\t]+$//;
        push(@matches, $_);
      }
    close (OTOOL);
   }

   # get list of depend pkgs
   foreach $match (@matches) {
    if (length($match) > 1) {
      ### FIXME, need to use open and close here
      open (SEARCH, "dpkg --search $match 2>/dev/null |") or die "can't run dpkg search: $!\n";
        while (<SEARCH>) {
          chomp();
          #next if;
          $_ =~ s/\:.*$//;		# strip out everything after the colon

          ### FIXME: add virtual and/or provides here to use || and && in pkgs.
          next if ($_ eq $pkgname);	# Can't dpend on it's self
          push(@depends, $_);
        }
      close(SEARCH);
    }
  }
 
  return @depends;
}
