#!perl

use strict;
use warnings;

use Test::More tests => 9;
use Test::Exception;

use Data::Dumper;

BEGIN { use_ok('App::MP4Meta::Source::TVDB'); }

my $tvdb;    # App::MP4Meta::Source::TVDB object

# search terms
my %search_terms = (
    show_title => 'men behaving badly',
    season     => 6,
    episode    => 1
);

# empty new
$tvdb = App::MP4Meta::Source::TVDB->new();
isa_ok( $tvdb, 'App::MP4Meta::Source::TVDB' );

throws_ok { $tvdb->get_episode( {} ) } qr/title/i, 'needs a title';

my $episode = $tvdb->get_episode( \%search_terms );
isa_ok( $episode, 'App::MP4Meta::Source::Data::TVEpisode' );
is( $episode->title, 'Stag Night', 'episode title' );
is(
    $episode->overview,
'Gary and Tony set out to celebrate Gary\'s stag night after Dorothy decides that it\'s time Gary showed ""real committment"" by marrying her. Gary suggests to Dorothy that buying a dog together might be an alternative!',
    'episode overview'
);
ok( -e $episode->cover, 'episode cover file' );
is( $episode->genre, 'Comedy', 'episode genre' );
is( $episode->year,  1997,     'episode year' );
