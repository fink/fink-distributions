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
use Fink::Config qw($basepath);
use Fink::Package;

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
our $depends_version = "0.2.0.cvs";
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
  my (@depends, $depend);
  my ($pkgversion);

  unless (defined $pkgname) {
    print "NOP\n";
    return;
  } 

  print "Scanning ${pkgname} for a list of lib depends\n\n";
  @depends = &check_pkg($pkgname);

  foreach $depend (@depends) {
    chomp($depend);
    if ($depend =~ /shlibs$/) {
      if ($show_shlibs eq "true") {
        $pkgversion = get_shlibsversion($depend);
        $depend = $pkgversion;
        $SHLIBS{$depend} = 1;
      }
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
  if (keys %PACKAGES) {    
    print "Depends: \${SHLIBS_DEPS}, ", join(', ', sort keys %PACKAGES), "\n\n";
  } else {
    print "Has no lib depends!\n\n";
  }

  return;
}

### Get Depend version
sub get_dependversion {
  my ($pattern);
  my ($vo, $lversion, @allnames, @selected, $pname, $package);

  Fink::Package->require_packages();
  @allnames = Fink::Package->list_packages();
  @selected = ();
  while (defined($pattern = shift)) {
    $pattern = lc quotemeta $pattern;
    push @selected, grep(/^$pattern$/, @allnames);
  }
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
  my (@depends, $depend, @files, $file, @matches, $match);

  # get files to test
  open(DPKG, "dpkg --listfiles $pkgname 2>/dev/null |") or die "can't run dpkg: $!\n";
  # iterate through the output of dpkg, looking for bins and libs
  while (<DPKG>) {
    chomp();
    next if (-d "$_");			# Drop  directories
#    if ("$_" =~ /\.dylib/) {		# Check for (.dylib) libs
      push(@files, $_);
#    } elsif ("$_" =~ /\.a/) {		# Check for (.a) libs
#      push(@files, $_);
#    } elsif ("$_" =~ /\.so/) {		# Check for (.so) libs
#      push(@files, $_);
#    } elsif ("$_" =~ /\/bin\//) {	# Check for anything in %p/bin
#      push(@files, $_);
#    } elsif ("$_" =~ /\/sbin\//) {	# Check for anything in %p/sbin
#      push(@files, $_);
    #} else {				# Drop everything else
#      next;
#    }
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
        next if ("$_" =~ /\/usr\/lib\//);	# Nuke system libs and 
        next if ("$_" =~ /\/System\/Library/);	# frameworks
        $_ =~ s/\ \(.*$//;			# Nuke the end
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
      ### FIXME: add virtual and/or provides here to use || and && in pkgs.
      next if ($depend eq $pkgname);	# Can't dpend on it's self
      push(@depends, $depend);
    }
  }
 
  return @depends;
}
