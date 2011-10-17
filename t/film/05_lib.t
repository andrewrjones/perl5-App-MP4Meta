#!perl

use strict;
use warnings;

use Test::More tests => 17;

BEGIN { use_ok('App::MP4Meta::Film'); }
require_ok('App::MP4Meta::Film');

# new
my $f = new_ok('App::MP4Meta::Film');

# parse_filename
my $title;
my $year;
( $title, $year ) = $f->_parse_filename('THE_TRUMAN_SHOW.m4v');
is( $title, 'The Truman Show' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE-TRUMAN-SHOW.m4v');
is( $title, 'The Truman Show' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE-TRUMAN_SHOW.m4v');
is( $title, 'The Truman Show' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE TRUMAN SHOW.m4v');
is( $title, 'The Truman Show' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE TRUMAN_SHOW.m4v');
is( $title, 'The Truman Show' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('IF....m4v');
is( $title, 'If...' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE_ITALIAN_JOB_2003.m4v');
is( $title, 'The Italian Job' );
is( $year,  2003 );
