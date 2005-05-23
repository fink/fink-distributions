#!/usr/bin/perl -w

use Scalar::Util qw(weaken);
use List::Util qw(reduce);

use Data::Dumper;

use strict;

use constant DEBUG => 1;

sub value {
    my $value = shift;
    ref $value ? "$value=$$value" : defined $value ? $value : "undef";
}

{
    my $options;
    &reset_options;

    sub reset_options {
	$options = {};
    }

    sub set_param_primary {
	my $param = shift;
	my $value = \$_[0];
	shift;
	$options->{$param}->[0] = $value;
    }

    sub set_param {
	my $param = shift;
	my $value = \$_[0];
	shift;
	if ( 1 == push @{$options->{$param}}, $value ) {
	    unshift @{$options->{$param}}, undef;
	}
    }

    sub set_param_temp {
	my $param = shift;
	my $value = \$_[0];
	shift;
	if ( 1 == push @{$options->{$param}}, $value ) {
	    unshift @{$options->{$param}}, undef;
	}
	weaken $options->{$param}->[-1];
    }

    sub print_param {
	my $param = shift;
	print "choices: ";
	print join ", ", map value($_), @{$options->{$param}};
	print "\n";
#	print Dumper $options->{$param};
    }

    sub param {
	my $param = shift;
	DEBUG && print_param($param);
	my $value = reduce { defined $b ? $b : $a } undef, @{$options->{$param}};
	return defined $value ? $$value : undef;
    }
}

my $value;

$value = param("foo");DEBUG && printf "foo=%s\n",value $value;
param("foo");
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;

#set_param("foo","foo1");
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;

{
    my $foo = "A";
    set_param_temp("foo",$foo);
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
    set_param_primary("foo","foofoo");
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
}
 
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;

set_param("foo","foo2");
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;
