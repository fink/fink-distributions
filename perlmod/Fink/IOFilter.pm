# -*- mode: Perl; tab-width: 4; -*-

package Fink::IOFilter;

require Tie::Handle;
our @ISA = qw/ Tie::StdHandle /;

use strict;

our $fh_stash = {};

=head1 NAME

	Fink::IOFilter - a 'tee'ed tied-filehandle

=head1 SYNOPSIS

	use Fink::IOFilter;
	Fink::IOFilter->tee_start(*STDOUT, $filename);
	print "testing 1 2 3\n";
	Fink::IOFilter->tee_stop(*STDOUT);

=head1 DESCRIPTION

Fink::IOFilter is a tied filehandle for redirecting output into multiple
places at once.

=head2 Methods

This class is a subclass of Tie::StdHandle. The following methods
override those in that superclass:

=over 4

=item TIEHANDLE

	tie NEW_FH, "Fink::IOFilter", $old_fh, $filename;
	TIEHANDLE "Fink::IOFilter", $old_fh, $filename;

Returns a writable filehandle bound to a newly-created Fink::IOFilter
object. The filehandle $old_fh must already be opened for writing. The
file $filename is opened for writing. A dup of $old_fh is saved before
NEW_FH is bound: if NEW_FH is $old_fh, one gets a Unixish "tee", not
endless recursion.

=cut

sub TIEHANDLE {
	my $class = shift;
	my $old_fh = shift;
	my $filename = shift;

	my $old_fileno = fileno($old_fh);

	open my $fh_dup, ">&$old_fileno" or die "Couldn't dup $old_fh: $!\n";
	open my $fh_log, '>>', $filename or die "Couldn't open $filename: $!\n";
	my $self = bless { filehandles => [ $fh_dup, $fh_log ] }, $class;
	return $self;
}

=item PRINT

	print $tied_Fink::IOFilter $string;
	print $tied_Fink::IOFilter @list;

Text printed to a filehandle tied to Fink::IOFilter is sent to $old_fh and
written to $filename (as defined during the tie: see the TIEHANDLE
method and tee_start function).

=cut

sub PRINT {
	my $self = shift;
	foreach (@{$self->{filehandles}}) {
		print $_ @_;
	}
}

=back

=head2 Functions

Several utility functions and class methods are available. These are
the usual interface for the package, though you're welcome to use the
underlying tie()able class.

=over 4

=item tee_start

	Fink::IOFilter->tee_start($filehandle, $filename);

Wrapper for TIEHANDLE that starts tee'ing the existing open and
writable $filehandle to the file $filename (appended if it already
exists).  You must pass $filehandle as a typeglob (*STDOUT or
*$lexical_fh).

=cut

sub tee_start {
	my $class = shift;
	my $filehandle = shift;
	my $filename = shift;

	tie $filehandle, $class, $filehandle, $filename;
}

=item tee_stop

	Fink::IOFilter::tee_stop $filehandle;

Stops tee'ing the $filehandle (as was passed to tee_start).

=cut

sub tee_stop {
	my $fh = shift;
	untie $fh;
}

=back

=cut

1;
