#!perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('App::MP4Meta::Base'); }
require_ok('App::MP4Meta::Base');

# new
my $b = new_ok('App::MP4Meta::Base');

# $self->{ap}
isa_ok( $b->{ap}, 'AtomicParsley::Command' );

undef $b;
