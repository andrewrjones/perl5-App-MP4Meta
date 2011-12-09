#!perl

use strict;
use warnings;

use Test::More tests => 30;

BEGIN { use_ok('App::MP4Meta::TV'); }
require_ok('App::MP4Meta::TV');

# new
my @args = ( { genre => 'Comedy' } );
my $t = new_ok( 'App::MP4Meta::TV', \@args );
isa_ok( $t->{ap}, 'AtomicParsley::Command' );
is( $t->{'genre'},      'Comedy' );
is( $t->{'media_type'}, 'TV Show' );

my $title;
my $season;
my $episode;

( $title, $season, $episode ) =
  $t->_parse_filename('Heroes.S03E01.HDTV.XviD-XOR.m4v');
is( $title,   'Heroes' );
is( $season,  3 );
is( $episode, 1 );
( $title, $season, $episode ) = $t->_parse_filename('gossip.girl.s01e01.m4v');
is( $title,   'Gossip Girl' );
is( $season,  1 );
is( $episode, 1 );
( $title, $season, $episode ) = $t->_parse_filename('THE_OFFICE-S1E3.m4v');
is( $title,   'The Office' );
is( $season,  1 );
is( $episode, 3 );
( $title, $season, $episode ) =
  $t->_parse_filename('THE_MIGHTY_BOOSH_S1E4.m4v');
is( $title,   'The Mighty Boosh' );
is( $season,  1 );
is( $episode, 4 );
( $title, $season, $episode ) = $t->_parse_filename('Dexter - s01e01.m4v');
is( $title,   'Dexter' );
is( $season,  1 );
is( $episode, 1 );
$t->{title} = 'Extras';
( $title, $season, $episode ) = $t->_parse_filename('S01E01.m4v');
is( $title,   'Extras' );
is( $season,  1 );
is( $episode, 1 );

my @episodes = (
    {
        date    => '9 July 2001',
        episode => '1',
        id      => '0664504',
        plot =>
'David Brent is the manager of the Slough branch of the Wernham Hogg paper company and he and some of his staff are having a bit of a rough morning after over-imbibing the night before. When his boss Jennifer Taylor-Clark drops in she tells him that the company can no longer afford both a Swindon and a Slough branch and that one is to be merged into the other. She also tells him there are going to be redundancies. Word spreads through the office quickly but David assures everyone that their jobs are safe.',
        season => '1',
        title  => 'Downsize'
    },
    {
        date    => '16 July 2001',
        episode => '2',
        id      => '0664509',
        plot =>
'David hires Donna, his lodger and the daughter of his best friend. While showing her round the office he discovers a doctored pornographic image of himself. Gareth, due to his covert operations skills, is told to catch the culprit.',
        season => '1',
        title  => 'Work Experience'
    },
);
my ( $episode_title, $episode_desc, $episode_year ) =
  $t->_get_episode_data( \@episodes, 1, 1 );
is( $episode_title, 'Downsize' );
is( $episode_desc,
'David Brent is the manager of the Slough branch of the Wernham Hogg paper company and he and some of his staff are having a bit of a rough morning after over-imbibing the night before. When his boss Jennifer Taylor-Clark drops in she tells him that the company can no longer afford both a Swindon and a Slough branch and that one is to be merged into the other. She also tells him there are going to be redundancies. Word spreads through the office quickly but David assures everyone that their jobs are safe.'
);
is( $episode_year, 2001 );

( $episode_title, $episode_desc, $episode_year ) =
  $t->_get_episode_data( \@episodes, 1, 2 );
is( $episode_title, 'Work Experience' );
is( $episode_desc,
'David hires Donna, his lodger and the daughter of his best friend. While showing her round the office he discovers a doctored pornographic image of himself. Gareth, due to his covert operations skills, is told to catch the culprit.'
);
is( $episode_year, 2001 );

undef $t;
