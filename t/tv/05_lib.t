#!perl

use strict;
use warnings;

use Test::More tests => 16;

BEGIN { use_ok('App::MP4Meta::TV'); }
require_ok('App::MP4Meta::TV');

# new
my $t = new_ok('App::MP4Meta::TV');
isa_ok( $t->{ap}, 'AtomicParsley::Command' );

my $title;
my $season;
my $episode;

( $title, $season, $episode ) =
  $t->_parse_filename('Heroes.S03E01.HDTV.XviD-XOR.m4v');
is( $title,   'Heroes' );
is( $season,  3 );
is( $episode, 1 );
( $title, $season, $episode ) = $t->_parse_filename('THE_OFFICE-S1E3.m4v');
is( $title,   'THE OFFICE' );
is( $season,  1 );
is( $episode, 3 );
( $title, $season, $episode ) =
  $t->_parse_filename('THE_MIGHTY_BOOSH_S1E4.m4v');
is( $title,   'THE MIGHTY BOOSH' );
is( $season,  1 );
is( $episode, 4 );
( $title, $season, $episode ) = $t->_parse_filename('Dexter - s01e01.m4v');
is( $title,   'Dexter' );
is( $season,  1 );
is( $episode, 1 );
