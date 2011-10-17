#!perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN { use_ok('App::MP4Meta::MusicVideo'); }
require_ok('App::MP4Meta::MusicVideo');

# new
my $f = new_ok('App::MP4Meta::MusicVideo');

# parse_filename
my $title;
my $artist;
( $title, $artist ) =
  $f->_parse_filename('Michael Jackson vs Prodigy - Bille Girl.m4v');
is( $title,  'Michael Jackson Vs Prodigy' );
is( $artist, 'Bille Girl' );
( $title, $artist ) = $f->_parse_filename(
    'Gotye - Somebody That I Used To Know (feat. Kimbra).m4v');
is( $title,  'Gotye' );
is( $artist, 'Somebody That I Used To Know (feat. Kimbra)' );
