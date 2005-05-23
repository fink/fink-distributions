#!/usr/bin/perl -w

use Scalar::Util qw(weaken);

use Data::Dumper;

use strict;

use constant DEBUG => 1;

sub value {
    my $value = shift;
    ref $value
	? defined $$value
	    ? "$value=$$value"
	    : "$value=undef"
	: defined $value
	    ? "$value"
	    : "undef";
}

{
    my $options;
    &reset_options;

    sub reset_options {
	$options = {};
    }

    sub set_param_primary {
	my $param = shift;
	my $value = shift;
	$options->{$param}->[0] = \$value;
    }

    sub set_param_sticky {
	my $param = shift;
	my $value = shift;
	$options->{$param}->[1] = \$value;
	splice @{$options->{$param}}, 2;
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

    sub set_param {
	die sprintf "No such function %s at %s line %s\n", (caller(0))[3,1,2];
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
	my $value;
	do {
	    $value = $options->{$param}->[-1];
	    return $$value if defined $value;
	    pop @{$options->{$param}};
	} while @{$options->{$param}};
	return undef;
    }
}

my $value;

$value = param("foo");DEBUG && printf "foo=%s\n",value $value;
param("foo");
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;

#set_param_sticky("foo","foo1");
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;

{
    my $foo = "A";
    set_param_temp("foo",$foo);
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
    set_param_primary("foo","foofoo");
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
}
 
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;

{
    my $foo = "B";
    set_param_temp("foo",$foo);
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
    my $foo2 = "C";
    set_param_temp("foo",$foo2);
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
    $foo2 = "D";
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
    set_param_sticky("foo","woot");
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
    set_param_sticky("foo",undef);
    $value = param("foo");DEBUG && printf "foo=%s\n",value $value;
}
 
$value = param("foo");DEBUG && printf "foo=%s\n",value $value;
