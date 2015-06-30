#!/usr/bin/perl

use FindBin;

use warnings;
use strict;

use Test::More tests => 6 * 3 + 1;
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
	secp521r1 => {
		i => "0037ade9319a89f4dabdb3ef411aaccca5123c61acab57b5393dce47608172a095aa85a30fe1c2952c6771d937ba9777f5957b2639bab072462f68c27a57382d4a52",
		gix => "0015417e84dbf28c0ad3c278713349dc7df153c897a1891bd98bab4357c9ecbee1e3bf42e00b8e380aeae57c2d107564941885942af5a7f4601723c4195d176ced3e",
		giy => "017cae20b6641d2eeb695786d8c946146239d099e18e1d5a514c739d7cb4a10ad8a788015ac405d7799dc75e7b7d5b6cf2261a6a7f1507438bf01beb6ca3926f9582",
		r => "0145ba99a847af43793fdd0e872e7cdfa16be30fdc780f97bccc3f078380201e9c677d600b343757a3bdbf2a3163e4c2f869cca7458aa4a4effc311f5cb151685eb9",
		grx => "00d0b3975ac4b799f5bea16d5e13e9af971d5e9b984c9f39728b5e5739735a219b97c356436adc6e95bb0352f6be64a6c2912d4ef2d0433ced2b6171640012d9460f",
		gry => "015c68226383956e3bd066e797b623c27ce0eac2f551a10c2c724d9852077b87220b6536c5c408a1d2aebb8e86d678ae49cb57091f4732296579ab44fcd17f0fc56a",
		girx => "01144c7d79ae6956bc8edb8e7c787c4521cb086fa64407f97894e5e6b2d79b04d1427e73ca4baa240a34786859810c06b3c715a3a8cc3151f2bee417996d19f3ddea",
		giry => "01b901e6b17db2947ac017d853ef1c1674e5cfe59cda18d078e05d1b5242adaa9ffc3c63ea05edb1e13ce5b3a8e50c3eb622e8da1b38e0bdd1f88569d6c99baffa43",
	},
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
