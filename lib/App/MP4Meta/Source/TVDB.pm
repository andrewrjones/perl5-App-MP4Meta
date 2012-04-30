use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::TVDB;

# ABSTRACT: Searches http://thetvbd.com for TV data.

use App::MP4Meta::Source::Base;
our @ISA = 'App::MP4Meta::Source::Base';

use App::MP4Meta::Source::Data::TVEpisode;

use WebService::TVDB;
use File::Temp  ();
use LWP::Simple ();

use constant NAME => 'theTVDB.com';

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = $class->SUPER::new($args);

    # TODO: specify language
    # TODO: API key?
    $self->{tvdb} = WebService::TVDB->new();

    return $self;
}

sub name {
    return NAME;
}

sub get_tv_episode {
    my ( $self, $args ) = @_;

    $self->SUPER::get_tv_episode($args);

    my $series_list = $self->{tvdb}->search( $args->{show_title} );

    die 'no series found' unless @$series_list;

    # TODO: ability to search results i.e. by year
    my $series = @{$series_list}[0];
    my $cover_file;

    if ( $self->{cache}->{ $series->id } ) {
        $series = $self->{cache}->{ $series->id };
    }
    else {

        # fetches full series data and cache
        $series->fetch();
        $series = $self->{cache}->{ $series->id } = $series;
    }

    # get banner file and cache
    if ( $self->{banner_cache}->{ $series->id . '-S' . $args->{season} } ) {
        $cover_file =
          $self->{banner_cache}->{ $series->id . '-S' . $args->{season} };
    }
    else {

        $cover_file =
          $self->{banner_cache}->{ $series->id . '-S' . $args->{season} } =
          $self->_get_cover_file( $series, $args->{season} );
    }

    # get episode
    my $episode = $series->get_episode( $args->{season}, $args->{episode} );

    return App::MP4Meta::Source::Data::TVEpisode->new(
        overview => $episode->Overview,
        title    => $episode->EpisodeName,
        genre    => $series->Genre->[0],
        cover    => $cover_file,
        year     => $episode->year,
    );
}

# gets the cover file for the season and returns the filename
# also stores in cache
sub _get_cover_file {
    my ( $self, $series, $season ) = @_;

    for my $banner ( @{ $series->banners } ) {
        if ( $banner->BannerType2 eq 'season' ) {
            if ( $banner->Season eq $season ) {
                my $temp = File::Temp->new( SUFFIX => '.jpg' );
                push @{ $self->{tempfiles} }, $temp;
                if (
                    LWP::Simple::is_success(
                        LWP::Simple::getstore( $banner->url, $temp->filename )
                    )
                  )
                {
                    return $temp->filename;
                }
            }
        }
    }
}

1;

=method new()

Create a new object. Takes no arguments

=method name()

Returns the name of this source.
