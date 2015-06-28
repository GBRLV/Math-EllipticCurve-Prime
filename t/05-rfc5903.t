#!/usr/bin/perl

use FindBin;

use warnings;
use strict;

use Test::More tests => 6 * 2 + 1;
use Test::NoWarnings;

use Math::BigInt try => 'GMP,FastCalc';
use Math::EllipticCurve::Prime;
use Math::EllipticCurve::Prime::Point;

my $tests = {
	secp256r1 => {
		i => "c88f01f510d9ac3f70a292daa2316de544e9aab8afe84049c62a9c57862d1433",
		gix => "dad0b65394221cf9b051e1feca5787d098dfe637fc90b9ef945d0c3772581180",
		giy => "5271a0461cdb8252d61f1c456fa3e59ab1f45b33accf5f58389e0577b8990bb3",
		r => "c6ef9c5d78ae012a011164acb397ce2088685d8f06bf9be0b283ab46476bee53",
		grx => "d12dfb5289c8d4f81208b70270398c342296970a0bccb74c736fc7554494bf63",
		gry => "56fbf3ca366cc23e8157854c13c58d6aac23f046ada30f8353e74f33039872ab",
		girx => "d6840f6b42f6edafd13116e0e12565202fef8e9ece7dce03812464d04b9442de",
		giry => "522bde0af0d8585b8def9c183b5ae38f50235206a8674ecb5d98edb20eb153a2",
	},
	secp384r1 => {
		i => "099f3c7034d4a2c699884d73a375a67f7624ef7c6b3c0f160647b67414dce655e35b538041e649ee3faef896783ab194",
		gix => "667842d7d180ac2cde6f74f37551f55755c7645c20ef73e31634fe72b4c55ee6de3ac808acb4bdb4c88732aee95f41aa",
		giy => "9482ed1fc0eeb9cafc4984625ccfc23f65032149e0e144ada024181535a0f38eeb9fcff3c2c947dae69b4c634573a81c",
		r => "41cb0779b4bdb85d47846725fbec3c9430fab46cc8dc5060855cc9bda0aa2942e0308312916b8ed2960e4bd55a7448fc",
		grx => "e558dbef53eecde3d3fccfc1aea08a89a987475d12fd950d83cfa41732bc509d0d1ac43a0336def96fda41d0774a3571",
		gry => "dcfbec7aacf3196472169e838430367f66eebe3c6e70c416dd5f0c68759dd1fff83fa40142209dff5eaad96db9e6386c",
		girx => "11187331c279962d93d604243fd592cb9d0a926f422e47187521287e7156c5c4d603135569b9e9d09cf5d4a270f59746",
		giry => "a2a9f38ef5cafbe2347cf7ec24bdd5e624bc93bfa82771f40d1b65d06256a852c983135d4669f8792f2c1d55718afbb4",
	},
	# TODO: add remaining curves
	#secp521r1 => {
	#},
};

foreach my $curvename (sort keys %$tests) {
	my $curve = Math::EllipticCurve::Prime->new(name => $curvename);
	next unless $curve;
	my $values = $tests->{$curvename};

	my %points;
	my %privs;
	foreach my $side (qw/i r/) {
		my $point = $curve->g->copy;
		my $priv = Math::BigInt->new("0x$values->{$side}");
		$point->bmul($priv);
		my $x = Math::BigInt->new("0x" . $values->{"g${side}x"});
		my $y = Math::BigInt->new("0x" . $values->{"g${side}y"});
		cmp_ok($x, '==', $point->x, "x-coordinate for side $side is good");
		cmp_ok($y, '==', $point->y, "y-coordinate for side $side is good");
		$points{$side} = $point;
		$privs{$side} = $priv;
	}

	my $ir = $points{i}->bmul($privs{r});
	my $ri = $points{r}->bmul($privs{i});
	cmp_ok($ir->x, '==', $ri->x, "x-coordinates match");
	cmp_ok($ir->y, '==', $ri->y, "y-coordinate match");
}
