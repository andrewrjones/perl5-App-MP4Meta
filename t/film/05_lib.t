#!perl

use strict;
use warnings;

use Test::More tests => 30;

BEGIN { use_ok('App::MP4Meta::Film'); }
require_ok('App::MP4Meta::Film');

# new
my $f = new_ok('App::MP4Meta::Film');
isa_ok( $f->{ap}, 'AtomicParsley::Command' );

# parse_filename
my $title;
my $year;
( $title, $year ) = $f->_parse_filename('THE_TRUMAN_SHOW.m4v');
is( $title, 'THE TRUMAN SHOW' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE-TRUMAN-SHOW.m4v');
is( $title, 'THE TRUMAN SHOW' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE-TRUMAN_SHOW.m4v');
is( $title, 'THE TRUMAN SHOW' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE TRUMAN SHOW.m4v');
is( $title, 'THE TRUMAN SHOW' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE TRUMAN_SHOW.m4v');
is( $title, 'THE TRUMAN SHOW' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('IF....m4v');
is( $title, 'IF...' );
ok( !$year );
( $title, $year ) = $f->_parse_filename('THE_ITALIAN_JOB_2003.m4v');
is( $title, 'THE ITALIAN JOB' );
is( $year,  2003 );

# get_cover_image
ok( !$f->_get_cover_image('cover.gif') );
my $cover_file = $f->_get_cover_image(
'http://ia.media-imdb.com/images/M/MV5BMjMzMTExMzU0NF5BMl5BanBnXkFtZTcwNDg0MDQyMQ@@._V1._SY317_CR5,0,214,317_.jpg'
);
ok( -e $cover_file, 'got cover file jpg' );    # later, we check its removed

# query_imdb
my $imdb = $f->_query_imdb('THE TRUMAN SHOW');
is( $imdb->title, 'The Truman Show' );
is( $imdb->storyline,
'In this movie, Truman is a man whose life is a fake one... The place he lives is in fact a big studio with hidden cameras everywhere, and all his friends and people around him, are actors who play their roles in the most popular TV-series in the world: The Truman Show. Truman thinks that he is an ordinary man with an ordinary life and has no idea about how he is exploited. Until one day... he finds out everything. Will he react?'
);
my @genres = @{ $imdb->genres };
my $genre  = $genres[0];
is( $genre,      'Comedy' );
is( $imdb->year, 1998 );

# year
$imdb = $f->_query_imdb('The Italian Job');
ok($imdb);
is( $imdb->year, 2003 );
$imdb = $f->_query_imdb( 'The Italian Job', 1969 );
ok($imdb);
is( $imdb->year, 1969 );

# no match
$imdb = $f->_query_imdb('sejkfnjeksnfjkasdkfuhekfjeafasf');
ok( !$imdb );

undef $f;

# ensure we clean up tmp files
ok( !-e $cover_file, 'removed cover file jpg' );
