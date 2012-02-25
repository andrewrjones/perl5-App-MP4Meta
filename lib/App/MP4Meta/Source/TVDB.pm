use strict;
use warnings;

package App::MP4Meta::Source::TVDB;

# ABSTRACT: Contains data for a TV Episode.

use App::MP4Meta::Source::Data::TVEpisode;

use Net::TVDB;
use File::Temp  ();
use LWP::Simple ();

use Data::Dumper;

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # TODO: specify language
    $self->{tvdb} = Net::TVDB->new();

    bless( $self, $class );
    return $self;
}

sub get_episode {
    my ( $self, $args ) = @_;

    die 'no title'   unless $args->{title};
    die 'no season'  unless $args->{season};
    die 'no episode' unless $args->{episode};

    my $series_list = $self->{tvdb}->search( $args->{title} );

    die 'no series found' unless @$series_list;

    # TODO: ability to search results i.e. by year
    my $series = @{$series_list}[0];

    # fetches full series data
    $series->fetch();

    # get banner
    my $cover_file;
    for my $banner ( @{ $series->banners } ) {
        if ( $banner->BannerType eq 'season' ) {
            if ( $banner->Season eq $args->{season} ) {
                my $temp = File::Temp->new( SUFFIX => '.jpg' );
                push @{ $self->{tempfiles} }, $temp;
                if (
                    LWP::Simple::is_success(
                        LWP::Simple::getstore( $banner->url, $temp->filename )
                    )
                  )
                {
                    $cover_file = $temp->filename;
                }
            }
        }
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

1;
