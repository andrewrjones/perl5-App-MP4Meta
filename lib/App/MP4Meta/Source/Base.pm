use strict;
use warnings;

package App::MP4Meta::Source::Base;

# ABSTRACT: Base class for sources

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # cache results
    $self->{cache}        = {};
    $self->{banner_cache} = {};

    bless( $self, $class );
    return $self;
}

sub get_film {
    my ( $self, $args ) = @_;

    die 'no title' unless $args->{title};
}

sub get_tv_episode {
    my ( $self, $args ) = @_;

    die 'no title'   unless $args->{show_title};
    die 'no season'  unless $args->{season};
    die 'no episode' unless $args->{episode};
}

1;
