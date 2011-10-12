#!perl

use strict;
use warnings;

use Test::More tests => 9;

BEGIN { use_ok('App::MP4Meta::Base'); }
require_ok('App::MP4Meta::Base');

# new
my $b = new_ok('App::MP4Meta::Base');

isa_ok( $b->{ap}, 'AtomicParsley::Command' );
ok( !$b->{'noreplace'} );

$b = App::MP4Meta::Base->new( { noreplace => 1 } );
ok( $b->{'noreplace'} );

is( $b->_clean_title('THE_OFFICE'), 'The Office' );
is( $b->_clean_title('EXTRAS'),     'Extras' );
is( $b->_clean_title('IF...'),      'If...' );

undef $b;
