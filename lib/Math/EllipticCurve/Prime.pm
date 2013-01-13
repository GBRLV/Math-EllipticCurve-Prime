use 5.006002;
use strict;
use warnings;

package Math::EllipticCurve::Prime;
# ABSTRACT: elliptic curve operations over prime fields

use Math::BigInt 1.78 try => 'GMP';
use Math::EllipticCurve::Prime::Point;

=head1 SYNOPSIS

	use Math::EllipticCurve::Prime;

	my $curve = Math::EllipticCurve::Prime->from_name('secp256r1');
	my $point = $curve->g; # Base point of the curve.
	$point->bdbl; # In-place operation.
	print "(" . $point->x . ", " . $point->y . ")\n";

=head1 DESCRIPTION

This class represents an elliptic curve over a prime field.  These curves are
commonly used in cryptography.  Consequently, a set of commonly-used curves (and
aliases for those curves) is provided by name.  The curve itself is generally
not very interesting; Math::EllipticCurve::Prime::Point will see much more use
in the typical scenario.

=cut

our %predefined = (
	secp192k1 => {
		p => "fffffffffffffffffffffffffffffffffffffffeffffee37",
		a => "00",
		b => "03",
		g => "04db4ff10ec057e9ae26b07d0280b7f4341da5d1b1eae06c7d9b2f2f6d9c5628a7844163d015be86344082aa88d95e2f9d",
		n => "fffffffffffffffffffffffe26f2fc170f69466a74defd8d",
		h => "01",
	},
	secp192r1 => {
		p => "fffffffffffffffffffffffffffffffeffffffffffffffff",
		a => "fffffffffffffffffffffffffffffffefffffffffffffffc",
		b => "64210519e59c80e70fa7e9ab72243049feb8deecc146b9b1",
		g => "04188da80eb03090f67cbf20eb43a18800f4ff0afd82ff101207192b95ffc8da78631011ed6b24cdd573f977a11e794811",
		n => "ffffffffffffffffffffffff99def836146bc9b1b4d22831",
		h => "01",
	},
	secp224r1 => {
		p => "ffffffffffffffffffffffffffffffff000000000000000000000001",
		a => "fffffffffffffffffffffffffffffffefffffffffffffffffffffffe",
		b => "b4050a850c04b3abf54132565044b0b7d7bfd8ba270b39432355ffb4",
		g => "04b70e0cbd6bb4bf7f321390b94a03c1d356c21122343280d6115c1d21bd376388b5f723fb4c22dfe6cd4375a05a07476444d5819985007e34",
		n => "ffffffffffffffffffffffffffff16a2e0b8f03e13dd29455c5c2a3d",
		h => "01",
	},
	secp256k1 => {
		p => "fffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f",
		a => "00",
		b => "07",
		g => "0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8",
		n => "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141",
		h => "01",
	},
	secp256r1 => {
		p => "ffffffff00000001000000000000000000000000ffffffffffffffffffffffff",
		a => "ffffffff00000001000000000000000000000000fffffffffffffffffffffffc",
		b => "5ac635d8aa3a93e7b3ebbd55769886bc651d06b0cc53b0f63bce3c3e27d2604b",
		g => "046b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2964fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5",
		n => "ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632551",
		h => "01",
	},
	secp384r1 => {
		p => "fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000ffffffff",
		a => "fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffeffffffff0000000000000000fffffffc",
		b => "b3312fa7e23ee7e4988e056be3f82d19181d9c6efe8141120314088f5013875ac656398d8a2ed19d2a85c8edd3ec2aef",
		g => "04aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab73617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f",
		n => "ffffffffffffffffffffffffffffffffffffffffffffffffc7634d81f4372ddf581a0db248b0a77aecec196accc52973",
		h => "01",
	},
	secp521r1 => {
		p => "01ffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff",
		a => "01fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffc",
		b => "0051953eb9618e1c9a1f929a21a0b68540eea2da725b99b315f3b8b489918ef109e156193951ec7e937b1652c0bd3bb1bf073573df883d2c34f1ef451fd46b503f00",
		g => "0400c6858e06b70404e9cd9e3ecb662395b4429c648139053fb521f828af606b4d3dbaa14b5e77efe75928fe1dc127a2ffa8de3348b3c1856a429bf97e7e31c2e5bd66011839296a789a3bc0045c8a5fb42c7d1bd998f54449579b446817afbd17273e662c97ee72995ef42640c550b9013fad0761353c7086a272c24088be94769fd16650",
		n => "01fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffa51868783bf2f966b7fcc0148f709a5d03bb5c9b8899c47aebb6fb71e91386409",
		h => "01",
	},
);

our %aliases = (
	P192 => "secp192r1",
	P224 => "secp224r1",
	P256 => "secp256r1",
	P384 => "secp384r1",
	P521 => "secp521r1",
);

=method new

Creates a new curve.  This function takes a hash of parameters.  The curve can
either be specified by name (parameter name) using a common name for the curve,
or the components can be specified individually.

The parameters are p, a prime; a and b, the constants which define the curve; g,
the base point, which functions as a generator; n, the order of g; and h, the
cofactor.  The integers can either be specified as hexadecimal strings or
Math::BigInt instances, and the base point can be specified either as an
instance of Meth::EllipticCurve::Prime::Point or a string suitable for that
class's from_hex function.

=cut

sub new {
	my ($class, %args) = @_;

	return $class->from_name($args{name}) if $args{name};

	my $self = \%args;
	$class = ref($class) || $class;
	bless $self, $class;
	return $self->init;
}

=method from_name

Takes a single argument, the name of the curve.

=cut

sub from_name {
	my ($class, $name) = @_;
	$name = $aliases{$name} if defined $aliases{$name};
	my $params = $predefined{$name};
	return unless defined $params;
	my $self = $class->new(%$params);
	$self->{name} = $name;
	return $self;
}

sub init {
	my $self = shift;
	foreach my $param (qw/p a b n h/) {
		$self->{$param} = Math::BigInt->new("0x$self->{$param}")
			unless ref $self->{$param};
	}
	$self->{g} = Math::EllipticCurve::Prime::Point->from_hex($self->{g})
		unless ref $self->{g};
	$self->{g}->curve($self);
	return $self;
}

=method name

Returns the canonical name of this curve if it was created by name.

=cut

sub name {
	my $self = shift;
	return $self->{name};
}

=method p

Returns a Math::BigInt representing p, the prime.

=cut

sub p {
	my $self = shift;
	return $self->{p};
}

=method a

Returns a Math::BigInt representing a, the coefficient of x and one of the
numbers which defines the curve.

=cut

sub a {
	my $self = shift;
	return $self->{a};
}

=method b

Returns a Math::BigInt representing b, the constant and one of the numbers
which defines the curve.

=cut

sub b {
	my $self = shift;
	return $self->{b};
}

=method g

Returns a Math::EllipticCurve::Prime::Point object representing g, the base
point and generator.

=cut

sub g {
	my $self = shift;
	return $self->{g};
}

=method n

Returns a Math::BigInt object representing n, the order of g.

=cut

sub n {
	my $self = shift;
	return $self->{n};
}

=method h

Returns a Math::BigInt object representing h, the cofactor.

=cut

sub h {
	my $self = shift;
	return $self->{h};
}


1;
