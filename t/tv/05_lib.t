#!perl

use strict;
use warnings;

use Test::More tests => 4;

BEGIN { use_ok('App::MP4Meta::TV'); }
require_ok('App::MP4Meta::TV');

# new
my $f = new_ok('App::MP4Meta::TV');
isa_ok( $f->{ap}, 'AtomicParsley::Command' );
