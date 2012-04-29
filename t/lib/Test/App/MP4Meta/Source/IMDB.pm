use 5.010;
use strict;
use warnings;

package Test::App::MP4Meta::Source::IMDB;
use base qw(TestBase);

use Test::More;

use App::MP4Meta::Source::IMDB;

# underscored so we run first
sub _create_new : Test(1) {
    my $self = shift;

    my $imdb = new_ok('App::MP4Meta::Source::IMDB');

    $self->{imdb} = $imdb;
}

sub name : Test(1) {
    my $self = shift;
    my $i    = $self->{imdb};

    is( $i->name, 'IMDB' );
}

sub live_tv_episode : Test(6) {
    my $self = shift;

    return 'no live testing' unless $self->can_live_test();

    my $i = $self->{imdb};

    my $f = $i->get_tv_episode(
        { show_title => 'Extras', season => 1, episode => 1 } );

    isa_ok( $f, 'App::MP4Meta::Source::Data::TVEpisode' );
    ok( $f->overview, 'got overview' );    # assume its sensible
    is( $f->title, 'Ben Stiller', 'got title' );
    is( $f->year,  2005,          'got year' );
    is( $f->genre, 'Comedy',      'got comedy' );

    local $TODO = 'can not currently get cover image for TV series from IMDB';
    like( $f->cover, qr/\.jpg$/, 'got cover image' );
}

sub live_film : Test(6) {
    my $self = shift;

    return 'no live testing' unless $self->can_live_test();

    my $i = $self->{imdb};

    my $f =
      $i->get_film( { title => 'Tinker Tailor Soldier Spy', year => 2011 } );

    isa_ok( $f, 'App::MP4Meta::Source::Data::Film' );
    ok( $f->overview, 'got overview' );    # assume its sensible
    is( $f->title, 'Tinker Tailor Soldier Spy', 'got title' );
    is( $f->year,  2011,                        'got year' );
    is( $f->genre, 'Drama',                     'got comedy' );

    like( $f->cover, qr/\.jpg$/, 'got cover image' );
}

1;
