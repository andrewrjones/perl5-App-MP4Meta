use 5.010;
use strict;
use warnings;

package App::MP4Meta::TV;

# ABSTRACT: Add metadata to a TV Series

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use File::Spec '3.33';
use HTML::TreeBuilder::XPath;
use AtomicParsley::Command::Tags;

# a list of regexes to try to parse the file
my @file_regexes = (
    qr/^S(?<season>\d)-E(?<episode>\d)\s+-\s+(?<show>.*)$/,
    qr/^(?<show>.*)\s+S(?<season>\d\d)E(?<episode>\d\d)$/,
    qr/^(?<show>.*)\.S(?<season>\d\d)E(?<episode>\d\d)/i,
    qr/^(?<show>.*) - S(?<season>\d\d?)E(?<episode>\d\d?)/i,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)/,
    qr/^(?<show>.*)_S(?<season>\d\d?)E(?<episode>\d\d?)/,
    qr/^S(?<season>\d\d?)E(?<episode>\d\d?)$/,
);

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($args);

    $self->{'genre'}     = $args->{'genre'};
    $self->{'title'}     = $args->{'title'};
    $self->{'coverfile'} = $args->{'coverfile'};

    $self->{'media_type'} = 'TV Show';

    return $self;
}

sub apply_meta {
    my ( $self, $path ) = @_;

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    # parse the filename for the title, season and episode
    my ( $show_title, $season, $episode ) = $self->_parse_filename($file);
    unless ( $show_title && $season && $episode ) {
        return "Error: could not parse the filename for $path";
    }

    # get data from IMDB
    my $imdb = $self->_query_imdb($show_title);
    unless ($imdb) {
        return "Error: could not find '$show_title' on the IMDB (for $path)";
    }

    unless ( $imdb->episodes() ) {
        return "Error: could not get episodes for '$show_title'";
    }
    my @episodes = @{ $imdb->episodes() };

    my ( $episode_title, $episode_desc, $year ) =
      $self->_get_episode_data( \@episodes, $season, $episode );
    unless ( $episode_title && $episode_desc ) {
        return "Error: could not get episodes for '$show_title'";
    }

    my @genres = @{ $imdb->genres };
    my $genre  = $genres[0];

    my $cover_file //= $self->{coverfile};
    unless ($cover_file) {
        $cover_file = $self->_get_cover_image( $imdb->cover );
    }

    my $tags = AtomicParsley::Command::Tags->new(
        artist       => $show_title,
        albumArtist  => $show_title,
        title        => $episode_title,
        album        => "$show_title, Season $season",
        tracknum     => $episode,
        TVShowName   => $show_title,
        TVEpisode    => $episode,
        TVEpisodeNum => $episode,
        TVSeasonNum  => $season,
        stik         => $self->{'media_type'},
        description  => $episode_desc,
        genre        => $genre,
        year         => $year,
        artwork      => $cover_file
    );

    return $self->_write_tags( $path, $tags );
}

# Parse the filename in order to get the series title the and season and episode number.
sub _parse_filename {
    my ( $self, $file ) = @_;

    # strip suffix
    $file =~ s/\.m4v$//;

    # see if we have a regex that matches
    for my $r (@file_regexes) {
        if ( $file =~ $r ) {
            my $show    = $self->{title} // $+{show};
            my $season  = $+{season};
            my $episode = $+{episode};

            if ( $show && $season && $episode ) {

                return ( $self->_clean_title($show), int $season,
                    int $episode );
            }
        }
    }

    return;
}

# get the episode data from the array
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

1;

=head1 SYNOPSIS

  my $tv = App::MP4Meta::TV->new({ genre => 'Comedy' });
  $tv->apply_meta( '/path/to/THE_MIGHTY_BOOSH_S1E1.m4v' );
  
=method apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=cut
