use 5.006002;
use strict;
use warnings;

package Math::EllipticCurve::Prime;
# ABSTRACT: elliptic curve operations over prime fields

use Math::BigInt try => 'GMP';
use Math::EllipticCurve::Prime::Point;

=head1 SYNOPSIS

use Math::EllipticCurve::Prime;

my $curve = Math::EllipticCurve::Prime->from_name('P-256');

=cut

our %predefined = (
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
);

our %aliases = (
	P256 => "secp256r1",
);

sub new {
	my ($class, %args) = @_;

	return $class->from_name($args{name}) if $args{name};

	my $self = \%args;
	$class = ref($class) || $class;
	bless $self, $class;
	return $self->init;
}

sub from_name {
	my ($class, $name) = @_;
	my $params = $predefined{$name};
	$params ||= $predefined{$aliases{$name}} if defined $aliases{$name};
	return unless defined $params;
	my $self = $class->new(%$params);
	$self->{name} = $name;
	return $self;
}

sub init {
	my $self = shift;
	foreach my $param (qw/p a b n h/) {
		$self->{$param} = Math::BigInt->new("0x$self->{$param}");
	}
	$self->{g} = Math::EllipticCurve::Prime::Point->from_hex($self->{g});
	$self->{g}->curve($self);
	return $self;
}

sub g {
	my $self = shift;
	return $self->{g};
}

sub a {
	my $self = shift;
	return $self->{a};
}

sub p {
	my $self = shift;
	return $self->{p};
}

1;
