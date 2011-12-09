#!perl

use strict;
use warnings;

use Test::More tests => 23;

BEGIN { use_ok('App::MP4Meta::Base'); }
require_ok('App::MP4Meta::Base');

# new
my $b = new_ok('App::MP4Meta::Base');
isa_ok( $b->{ap}, 'AtomicParsley::Command' );

isa_ok( $b->{ap}, 'AtomicParsley::Command' );
ok( !$b->{'noreplace'} );

$b = App::MP4Meta::Base->new( { noreplace => 1 } );
ok( $b->{'noreplace'} );

is( $b->_clean_title('THE_OFFICE'),  'The Office' );
is( $b->_clean_title('Gossip.girl'), 'Gossip Girl' );
is( $b->_clean_title('EXTRAS'),      'Extras' );
is( $b->_clean_title('IF...'),       'If...' );

# get_cover_image
ok( !$b->_get_cover_image('cover.gif') );
my $cover_file = $b->_get_cover_image(
'http://ia.media-imdb.com/images/M/MV5BMjMzMTExMzU0NF5BMl5BanBnXkFtZTcwNDg0MDQyMQ@@._V1._SY317_CR5,0,214,317_.jpg'
);
ok( -e $cover_file, 'got cover file jpg' );    # later, we check its removed

# query_imdb
my $imdb = $b->_query_imdb('THE TRUMAN SHOW');
is( $imdb->title, 'The Truman Show' );
is( $imdb->storyline,
'In this movie, Truman is a man whose life is a fake one... The place he lives is in fact a big studio with hidden cameras everywhere, and all his friends and people around him, are actors who play their roles in the most popular TV-series in the world: The Truman Show. Truman thinks that he is an ordinary man with an ordinary life and has no idea about how he is exploited. Until one day... he finds out everything. Will he react?'
);
my @genres = @{ $imdb->genres };
my $genre  = $genres[0];
is( $genre,      'Comedy' );
is( $imdb->year, 1998 );

# year
$imdb = $b->_query_imdb('The Italian Job');
ok($imdb);
is( $imdb->year, 2003 );
$imdb = $b->_query_imdb( 'The Italian Job', 1969 );
ok($imdb);
is( $imdb->year, 1969 );

# no match
$imdb = $b->_query_imdb('sejkfnjeksnfjkasdkfuhekfjeafasf');
ok( !$imdb );

undef $b;

# ensure we clean up tmp files
ok( !-e $cover_file, 'removed cover file jpg' );
