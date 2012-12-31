#!/usr/bin/perl

use warnings;
use strict;

use Test::More tests => 14 + 1;
use Test::NoWarnings;

use Math::BigInt try => 'GMP';
use Math::EllipticCurve::Prime;

foreach my $name (sort keys %Math::EllipticCurve::Prime::predefined) {
	my $curve = Math::EllipticCurve::Prime->new(name => $name);

	isa_ok($curve, "Math::EllipticCurve::Prime");
	my $g = $curve->g;
	my $x = $g->x;
	my $y = $g->y;
	my $left = $y->copy->bmodpow(2, $curve->p);
	my $right = $x->copy->bmodpow(3, $curve->p);
	$right->badd($x->copy->bmul($curve->a));
	$right->badd($curve->b);
	$right->bmod($curve->p);

	is($left, $right, "base point for $name is on the curve");
}
