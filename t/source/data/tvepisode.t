#!perl

use strict;
use warnings;

use Test::More tests => 2;

BEGIN { use_ok('App::MP4Meta::Source::Data::TVEpisode'); }

my $episode;    # App::MP4Meta::Source::Data::TVEpisode object

# empty new
$episode = App::MP4Meta::Source::Data::TVEpisode->new();
isa_ok( $episode, 'App::MP4Meta::Source::Data::TVEpisode' );
