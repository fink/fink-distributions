#!/usr/bin/perl

use File::Basename;

my %PACKAGES;
my @TREES;
my $prefix;

my $do_md5 = 0;

if (grep(/^-m$/, @ARGV)) {
	$do_md5++;
	@ARGV = grep(!/^-m$/, @ARGV);
}

if (grep(/^-h$/, @ARGV)) {
	print <<END;
usage: $0 [-m] [tree1] [tree2] ... [treeN]

	-m	check md5sums of info files (slow!)

END
	exit 0;
}

if (@ARGV) {
	@TREES = @ARGV;
} else {
	if (opendir(DIR, dirname($0))) {
		$prefix = dirname($0);
		for my $dir (grep(!/^\.\.?$/, readdir(DIR))) {
			push(@TREES, $prefix . '/' . $dir);
		}
	} else {
		die "couldn't read from " . dirname($0) . ": $!\n";
	}
}

for my $tree (@TREES) {
	my $treename = $tree;
	$treename =~ s#/*$##;
	$treename =~ s#^.*/##;

	my $find = "find $tree -name '*.info'";
	if ($do_md5) {
		$find .= ' | xargs /sw/bin/md5sum';
	}
	$find .= ' |';
	if (open(FIND, $find)) {
		while (my $file = <FIND>) {
			chomp $file;
			($md5sum, $file) = split(/\s+/, $file) if ($do_md5);
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
							push(@{$PACKAGES{$packname}->{version}->{get_verstring($epoch, $version, $revision)}}, $treename . '/' . $stable);
							if ($do_md5) {
								push(@{$PACKAGES{$packname}->{md5s}->{get_verstring($epoch, $version, $revision)}->{$md5sum}}, $treename . '/' . $stable);
							}
						}
						$packname = $package;
					}
				}
				close(INFO);
				$packname =~ s/\%N/$firstpack/g;
				push(@{$PACKAGES{$packname}->{version}->{get_verstring($epoch, $version, $revision)}}, $treename . '/' . $stable);
				if ($do_md5) {
					push(@{$PACKAGES{$packname}->{md5s}->{get_verstring($epoch, $version, $revision)}->{$md5sum}}, $treename . '/' . $stable);
				}
			} else {
				warn "unable to open $file: $!\n";
			}
		}
		close(FIND);
	} else {
		warn "find failed in tree $treename, skipping: $!\n";
	}
}

for my $package (sort keys %PACKAGES) {
	my $output = $package . ":\n";
	for my $version (sort keys %{$PACKAGES{$package}->{version}}) {
		$output .= sprintf('  %-20s ', $version);
		$output .= join(", ", @{$PACKAGES{$package}->{version}->{$version}});
		if ($do_md5) {
			if (%{$PACKAGES{$package}->{md5s}->{$version}} > 1) {
				$output .= " (md5's don't match)\n";
				for my $md5sum (sort keys %{$PACKAGES{$package}->{md5s}->{$version}}) {
					$output .= " " x 27 . $md5sum . ": ";
					$output .= join(', ', @{$PACKAGES{$package}->{md5s}->{$version}->{$md5sum}});
					$output .= "\n";
				}
			} else {
				$output .= "\n";
			}
		} else {
			$output .= "\n";
		}
	}
	$output =~ s/\n*$//;
	print $output, "\n\n";
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
