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
    qr/^(?<show>.*)\s+S(?<season>\d\d)(\s|)E(?<episode>\d\d)$/,
    qr/^(?<show>.*)\.S(?<season>\d\d)E(?<episode>\d\d)/i,
    qr/^(?<show>.*) - S(?<season>\d\d?)E(?<episode>\d\d?)/i,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)/,
    qr/^(?<show>.*)_S(?<season>\d\d?)E(?<episode>\d\d?)/,
    qr/S(?<season>\d\d?)E(?<episode>\d\d?)/,
);

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($args);

    $self->{'without_imdb'} = $args->{'without_imdb'};

    $self->{'genre'}     = $args->{'genre'};
    $self->{'title'}     = $args->{'title'};
    $self->{'coverfile'} = $args->{'coverfile'};

    $self->{'media_type'} = 'TV Show';

    return $self;
}

sub apply_meta {
    my ( $self, $path ) = @_;
    my %tags;

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    # parse the filename for the title, season and episode
    ( $tags{show_title}, $tags{season}, $tags{episode} ) =
      $self->_parse_filename($file);
    unless ( $tags{show_title} && $tags{season} && $tags{episode} ) {
        return "Error: could not parse the filename for $path";
    }

    # get data from IMDB
    my $imdb = $self->_query_imdb( $tags{show_title} );
    if ($imdb) {

        unless ( $imdb->episodes() ) {
            my $error = "Error: could not get episodes for '$tags{show_title}'";
            unless ( $self->without_imdb ) {
                return $error;
            }
            else {
                say $error . ", continuing";
            }
        }
        my @episodes = @{ $imdb->episodes() };

        my @genres = @{ $imdb->genres };
        $tags{genre} = $genres[0];

        $tags{cover_file} //= $self->{coverfile};
        unless ( $tags{cover_file} ) {
            $tags{cover_file} = $self->_get_cover_image( $imdb->cover );
        }

        ( $tags{episode_title}, $tags{episode_desc}, $tags{year} ) =
          $self->_get_episode_data( \@episodes, $tags{season}, $tags{episode} );
        unless ( $tags{episode_title} && $tags{episode_desc} ) {
            my $error = "Error: could not get episodes for '$tags{show_title}'";
            unless ( $self->without_imdb ) {
                return $error;
            }
            else {
                say $error . ", continuing";
            }
        }

    }
    else {
        my $error =
          "Error: could not find '$tags{show_title}' on the IMDB (for $path)";
        unless ( $self->without_imdb ) {
            return $error;
        }
        else {
            say $error . ", continuing";
        }
    }

    my $apTags = AtomicParsley::Command::Tags->new(
        artist       => $tags{show_title},
        albumArtist  => $tags{show_title},
        title        => $tags{episode_title},
        album        => "$tags{show_title}, Season $tags{season}",
        tracknum     => $tags{episode},
        TVShowName   => $tags{show_title},
        TVEpisode    => $tags{episode},
        TVEpisodeNum => $tags{episode},
        TVSeasonNum  => $tags{season},
        stik         => $self->{'media_type'},
        description  => $tags{episode_desc},
        genre        => $tags{genre},
        year         => $tags{year},
        artwork      => $tags{cover_file}
    );

    return $self->_write_tags( $path, $apTags );
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
