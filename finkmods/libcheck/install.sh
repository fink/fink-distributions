#!/bin/sh -e
#
# install.sh - install fink package
#
# Fink - a package manager that downloads source and installs it
# Copyright (c) 2001 Christoph Pfisterer
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

if [ $# -ne 1 ]; then
  echo "Usage: ./install.sh <prefix>"
  echo "  Example: ./install.sh /tmp/builddirectory/sw"
  echo "WARNING: Don't call install.sh directly, use inject.pl instead."
  echo "         You have been warned."
  exit 1
fi

basepath="$1"


echo "Creating directories..."

mkdir -p "$basepath"
chmod 755 "$basepath"

for dir in bin lib lib/perl5 lib/perl5/Fink \
	   share share/doc share/doc/fink-libcheck ; do
  mkdir "$basepath/$dir"
  chmod 755 "$basepath/$dir"
done


echo "Copying files..."

install -c -p -m 755 fink-libcheck "$basepath/bin/"

for file in perlmod/Fink/*.pm ; do
  if [ -f $file ]; then
    install -c -p -m 644 $file "$basepath/lib/perl5/Fink/"
  fi
done

for file in COPYING README INSTALL ; do
  install -c -p -m 644  $file "$basepath/share/doc/fink-libcheck/"
done


echo "Done."
exit 0
