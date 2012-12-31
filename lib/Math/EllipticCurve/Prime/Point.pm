use 5.006002;
use strict;
use warnings;

package Math::EllipticCurve::Prime::Point;
# ABSTRACT: points for elliptic curve operations over prime fields

use Math::BigInt try => 'GMP';

=method new

Create a new point.  This constructor takes a hash as its sole argument.  If the
arguments x and y are both provided, assumes that these are instances of
Math::BigInt.  If x and y are not both provided, creates a new point at
infinity.

=cut

sub new {
	my ($class, %args) = @_;

	if (!defined $args{x} && !defined $args{y} && !defined $args{infinity}) {
		$args{infinity} = 1;
	}
	$args{infinity} ||= 0;
	delete @args{qw/x y/} if $args{infinity};

	$args{curve} = Math::EllipticCurve::Prime->from_name($args{curve})
		if $args{curve} && !ref $args{curve};

	my $self = \%args;
	$class = ref($class) || $class;
	return bless $self, $class;
}

=method from_hex

This method takes a hexadecimal-encoded representation of a point in the SEC
format and creates a new Math::EllipticCurve::Prime::Point object.  Currently
this only understands uncompressed points (first byte 0x04) and the point at
infinity.

=cut

sub from_hex {
	my ($class, $hex) = @_;

	return $class->new if substr($hex, 0, 2) eq "00";
	return unless substr($hex, 0, 2) eq "04";
	$hex = substr($hex, 2);
	my $len = length $hex;
	return if $len & 4;
	my ($x, $y) = map {
		Math::BigInt->new("0x$_")
	} (substr($hex, 0, $len / 2), substr($hex, $len / 2));
	return $class->new(x => $x, y => $y);
}

=method from_hex

This method takes a representation of a point in the SEC format and creates a
new Math::EllipticCurve::Prime::Point object.  Calls from_hex under the
hood.

=cut

sub from_bytes {
	my ($class, $bytes) = @_;
	return $class->from_hex(pack "H*", $bytes);
}

=method copy

Makes a copy of the current point.

=cut

sub copy {
	my $self = shift;
	return $self->new(x => $self->{x}->copy, y => $self->{y}->copy,
		curve => $self->{curve});
}

=method clone

A synonym for copy.

=cut

*clone = \&copy;

sub _set_infinity {
	my $self = shift;

	$self->{infinity} = 1;
	delete @{$self}{qw/x y/};

	return $self;
}

=method bmul

Multiplies this point by a scalar.  The scalar should be a Math::BigInt.  Like
Math::BigInt, this modifies the present point.  If you want to preserve this
point, use the copy method to create a clone of the current point.

Requires that a curve has been set.

=cut

sub bmul {
	my ($self, $k) = @_;

	my $bits = $k->copy->blog(2);
	my $mask = Math::BigInt->bone->blsft($bits);
	my $pt = $self->copy;

	$self->_set_infinity;

	for (reverse 0..$bits) {
		$self->bdbl;
		if ($k->copy->band($mask)) {
			$self->badd($pt);
		}
		$mask->brsft(1);
	}
	return $self;
}

# A helper to do the boring and repetitive parts of point addition.
sub _add_points {
	my ($self, $x1, $x2, $y1, $lambda, $p) = @_;

	my $x = $lambda->copy->bmodpow(2, $p);
	$x->bsub($x1);
	$x->bsub($x2);
	$x->bmod($p);

	my $y = $x1->copy->bsub($x);
	$y->bmul($lambda);
	$y->bsub($y1);
	$y->bmod($p);

	@{$self}{qw/x y/} = ($x, $y);
	return $self;
}

=method badd

Adds this point to another point.  Like Math::BigInt, this modifies the present
point.  If you want to preserve this point, use the copy method to create a
clone of the current point.

Requires that a curve has been set.

=cut

# The algorithm used here is specified in SEC 1, page 7.
sub badd {
	my ($self, $other) = @_;

	die "Can't add a point without a curve" unless $self->curve;

	if ($self->infinity && $other->infinity) {
		return $self;
	}
	elsif ($other->infinity) {
		return $self;
	}
	elsif ($self->infinity) {
		$self->{infinity} = 0;
		@{$self}{qw/x y/} = map { $_->copy } @{$other}{qw/x y/};
		return $self;
	}
	elsif ($self->{x}->bcmp($other->{x})) {
		my $p = $self->curve->p;
		my $lambda = $other->y->copy->bsub($self->y);
		my $bottom = $other->x->copy->bsub($self->x)->bmodinv($p);
		$lambda->bmul($bottom)->bmod($p);

		return $self->_add_points($self->x, $other->x, $self->y, $lambda, $p);
	}
	elsif ($self->{y}->is_zero || $other->{y}->is_zero ||
		$self->{y}->bcmp($other->{y})) {

		return $self->_set_infinity;
	}
	else {
		return $self->bdbl;
	}
}

=method bdbl

Doubles the current point.  Like Math::BigInt, this modifies the present point.
If you want to preserve this point, use the copy method to create a clone of the
current point.

Requires that a curve has been set.

=cut

# The algorithm used here is specified in SEC 1, page 7.
sub bdbl {
	my $self = shift;

	return $self if $self->infinity;

	die "Can't multiply or double a point without a curve"
		unless defined $self->{curve};
	
	my $p = $self->curve->p;
	my $lambda = $self->x->copy->bmodpow(2, $p);
	$lambda->bmul(3);
	$lambda->badd($self->curve->a);
	my $bottom = $self->y->copy->bmul(2)->bmodinv($p);
	$lambda->bmul($bottom)->bmod($p);

	return $self->_add_points($self->x, $self->x, $self->y, $lambda, $p);
}

=method multiply

Multiplies this point by a scalar.  Returns a new point object.

Requires that a curve has been set.

=cut

sub multiply {
	my ($self, $k) = @_;
	return $self->copy->bmul($k);
}

=method add

Adds this point to another point.  Returns a new point object.

Requires that a curve has been set.

=cut

sub add {
	my ($self, $other) = @_;
	return $self->copy->badd($other);
}

=method double

Doubles this point.  Returns a new point object.

Requires that a curve has been set.

=cut

sub double {
	my $self = shift;
	return $self->copy->bdbl;
}

=method infinity

Returns true if this point is the point at infinity, false otherwise.

=cut

sub infinity {
	my $self = shift;
	return $self->{infinity};
}

=method x

Returns a Math::BigInt representing the x-coordinate of the point.  Returns
undef if this is the point at infinity.  You should make a copy of the returned
object; otherwise, you will modify the point.

=cut

sub x {
	my $self = shift;
	return $self->{x};
}

=method y

Returns a Math::BigInt representing the y-coordinate of the point.  Returns
undef if this is the point at infinity.  You should make a copy of the returned
object; otherwise, you will modify the point.

=cut

sub y {
	my $self = shift;
	return $self->{y};
}

=method curve

Returns the Math::EllipticCurve::Prime curve associated with this point, if any.
Optionally takes an argument to set the curve.

=cut

sub curve {
	my ($self, $curve) = @_;

	$self->{curve} = $curve if defined $curve;
	return $self->{curve};
}

1;
