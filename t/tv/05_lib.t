#!perl

use strict;
use warnings;

use Test::More tests => 24;

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

my $tmpfile = $t->_get_wikipedia_page(
    'http://en.wikipedia.org/w/index.php?title=List of Extras episodes');
ok( -e $tmpfile );

my ( $episode_title, $episode_desc ) = $t->_query_wikipedia( 'Extras', 1, 1 );
is( $episode_title, 'Ben Stiller' );
is( $episode_desc,
'Andy and Maggie are playing extras in the film Ben Stiller is directing, which is based on the life of Goran, an Eastern European man whose wife and son were killed in the Yugoslav Wars. Andy attempts to get a speaking part by befriending Goran, who eventually gets Andy a spoken line. However, Andy gets in an argument with Stiller just before shooting his scene and is kicked off the set. Maggie, meanwhile, takes an interest in one of the crew but it goes wrong after Andy points out that her would-be beau has one leg shorter than the other, which Maggie is unable to stop herself making an issue of.'
);

( $episode_title, $episode_desc ) = $t->_query_wikipedia( 'Extras', 2, 1 );
is( $episode_title, 'Orlando Bloom' );
is( $episode_desc,
'Andy\'s new sitcom, When The Whistle Blows, is being filmed, whilst Maggie appears as an extra in a courtroom drama with Orlando Bloom and Sophia Myles. The audience find the heavily-rewritten sitcom funny but Andy, forced to wear glasses and a wig, feels like he has sold out, particularly when dim-witted and un-PC Keith Chegwin is cast in a cameo role. The character Alfie (renamed Keith by Andy when Chegwin proves unable to respond to being addressed by any name other than his own) is cast as was meant to be played by Keith Harris, but Harris declined the role of Alfie, stating \"Ricky Gervais wanted me to be a racist bigot\". Meanwhile, Orlando Bloom refuses to believe that Maggie does not find him attractive and waxes lyrical about his dislike for Johnny Depp.'
);

( $episode_title, $episode_desc ) = $t->_query_wikipedia( 'House', 2, 1 );
is( $episode_title, 'Acceptance' );
is( $episode_desc,
'House is brought in for a consult on a Death Row inmate (LL Cool J) with mysterious symptoms. Cameron feels the hospital\'s resources are better used elsewhere for a young cancer patient. House and Stacy try to establish a good work relationship, especially after he lies to her to secure the transfer of the inmate to the hospital.Final diagnosis: Methanol poisoning and pheochromocytoma (Clarence) and Lung cancer (Cindy)'
);

undef $t;
ok( !-e $tmpfile );
