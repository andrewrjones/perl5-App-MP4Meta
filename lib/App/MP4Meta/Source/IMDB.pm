use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::IMDB;

# ABSTRACT: Contains data for a TV Episode.

use App::MP4Meta::Source::Base;
our @ISA = 'App::MP4Meta::Source::Base';

use App::MP4Meta::Source::Data::TVEpisode;

use IMDB::Film 0.52;
use File::Temp  ();
use LWP::Simple ();

use constant NAME => 'IMDB';

sub name {
    return NAME;
}

sub get_film {
    my ( $self, $args ) = @_;

    $self->SUPER::get_film($args);

    # film data
    my $title;
    my $overview;
    my $genre;
    my $year;
    my $cover_file;

    my $imdb = $self->_search_imdb( $args->{title}, $args->{year} );

    # get genre
    my @genres = @{ $imdb->genres };
    $genre = $genres[0];

    # get cover file
    unless ($cover_file) {
        $cover_file = $self->_get_cover_file( $imdb->cover );
    }

    return App::MP4Meta::Source::Data::Film->new(
        overview => $imdb->storyline,
        title    => $imdb->title,
        genre    => $genre,
        cover    => $cover_file,
        year     => $imdb->year,
    );
}

sub get_tv_episode {
    my ( $self, $args ) = @_;

    $self->SUPER::get_tv_episode($args);

    # episode data
    my $title;
    my $overview;
    my $genre;
    my $year;
    my $cover_file;

    # do the search
    # TODO: how can I mock?
    my $imdb = $self->_search_imdb( $args->{show_title}, $args->{year} );

    my @episodes = @{ $imdb->episodes() };

    # get genre
    my @genres = @{ $imdb->genres };
    $genre = $genres[0];

    # get cover file
    unless ($cover_file) {
        $cover_file = $self->_get_cover_file( $imdb->cover );
    }

    # get the episode
    ( $title, $overview, $year ) =
      $self->_get_episode_data( \@episodes, $args->{season}, $args->{episode} );

    return App::MP4Meta::Source::Data::TVEpisode->new(
        overview => $overview,
        title    => $title,
        genre    => $genre,
        cover    => $cover_file,
        year     => $year,
    );
}

# search on the IMDB
sub _search_imdb {
    my ( $self, $title, $year ) = @_;

    my $imdb = IMDB::Film->new( crit => $title, year => $year );
    die 'no series found' unless $imdb->status;

    return $imdb;
}

# get the episode data from the episodes array
sub _get_episode_data {
    my ( $self, $episodes, $season, $episode ) = @_;

    for my $e ( @{$episodes} ) {
        if ( $e->{season} == $season && $e->{episode} == $episode ) {
            my $year;
            if ( $e->{date} =~ /(\d{4})$/ ) {
                $year = $1;
            }
            return ( $e->{title}, $e->{plot}, $year );
        }
    }
    return;
}

# gets the cover file for the season and returns the filename
# also stores in cache
sub _get_cover_file {
    my ( $self, $url ) = @_;

    my $temp = File::Temp->new( SUFFIX => '.jpg' );
    push @{ $self->{tempfiles} }, $temp;
    if (
        LWP::Simple::is_success(
            LWP::Simple::getstore( $url, $temp->filename )
        )
      )
    {
        return $temp->filename;
    }
}

1;

=method name()

Returns the name of this source.
