#!/usr/bin/perl

use File::Basename;

my %PACKAGES;
my @TREES;

if (@ARGV) {
	@TREES = @ARGV;
} else {
	if (opendir(DIR, dirname($0))) {
		@TREES = grep(!/^\.\.?$/, readdir(DIR));
	} else {
		die "couldn't read from " . dirname($0) . ": $!\n";
	}
}

for my $tree (@TREES) {
	my $treename = $tree;
	$treename =~ s#/*$##;
	$treename =~ s#^.*/##;

	if (open(FIND, "find $tree -name '*.info' |")) {
		while (my $file = <FIND>) {
			chomp;
			if (open(INFO, $file)) {
				my $firstpack = "";
				my $packname  = "";
				my $version   = 0;
				my $revision  = 0;
				my $epoch     = 0;
				my $stable    = "stable";
				   $stable    = "unstable" if ($file =~ m#/unstable/#);
				while (<INFO>) {
					if (/^\s*version:\s*(\S+)\s*$/i) {
						$version = $1;
					} elsif (/^\s*revision:\s*(\S+)\s*$/i) {
						$revision = $1;
					} elsif (/^\s*epoch:\s*(\S+)\s*$/i) {
						$epoch = $1;
					} elsif (/^\s*package:\s*(\S+)\s*$/i) {
						my $package = $1;
						if ($firstpack eq "") {
							$firstpack = $package;
						}
						$package =~ s/\%N/$firstpack/i;
						if ($packname ne "") {
							push(@{$PACKAGES{$packname}->{get_verstring($epoch, $version, $revision)}}, $tree . '/' . $stable);
						}
						$packname = $package;
					}
				}
				close(INFO);
				$packname =~ s/\%N/$firstpack/g;
				push(@{$PACKAGES{$packname}->{get_verstring($epoch, $version, $revision)}}, $tree . '/' . $stable);
			} else {
				warn "unable to open $file: $!\n";
			}
		}
		close(FIND);
	} else {
		warn "find failed in tree $tree, skipping: $!\n";
	}
}

for my $package (sort keys %PACKAGES) {
	print $package, ":\n";
	for my $version (sort keys %{$PACKAGES{$package}}) {
		printf('  %-20s: ', $version);
		print join(", ", @{$PACKAGES{$package}->{$version}}), "\n";
	}
	print "\n";
}

sub get_verstring {
	my $epoch    = shift;
	my $version  = shift;
	my $revision = shift;

	if ($epoch) {
		return $epoch . ':' . $version . '-' . $revision;
	} else {
		return $version . '-' . $revision;
	}
}
