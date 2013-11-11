use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::IMDB;

# ABSTRACT: Fetches film data from the IMDB.

use App::MP4Meta::Source::Base;
our @ISA = 'App::MP4Meta::Source::Base';

use App::MP4Meta::Source::Data::Film;

use WebService::IMDBAPI;
use File::Temp  ();
use LWP::Simple ();

use constant NAME => 'IMDB';

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new($args);

    $self->{imdb} = WebService::IMDBAPI->new();

    return $self;
}

sub name {
    return NAME;
}

sub get_film {
    my ( $self, $args ) = @_;

    $self->SUPER::get_film($args);

    my $result = $self->{imdb}->search_by_title(
        $args->{title},
        {
            year    => $args->{year},
            limit   => 1,
            episode => 0
        }
    )->[0];

    # get cover file
    # FIXME: never set
    my $cover_file;
    unless ($cover_file) {

        my $poster;
        if ( UNIVERSAL::isa( $result->poster, "HASH" ) ) {
            $poster = $result->poster->{cover} || $result->poster->{imdb};
        }
        else {
            $poster = $result->poster;
        }
        $cover_file = $self->_get_cover_file($poster);
    }

    # FIXME: poster could be null.

    return App::MP4Meta::Source::Data::Film->new(
        overview => $result->plot_simple,
        title    => $result->title,
        genre    => $result->genres->[0],
        cover    => $cover_file,
        year     => $result->year,
    );
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

__END__

=method name()

Returns the name of this source.
