use strict;
use warnings;

package App::MP4Meta::Source::Data::Base;

# ABSTRACT: Base class for metadata.

use Object::Tiny qw(
  cover
  genre
  overview
  title
  year
);

sub merge {
    my ( $self, $to_merge ) = @_;

    while ( my ( $key, $value ) = each(%$to_merge) ) {
        $self->{$key} = $value unless $self->{$key};
    }
}

1;

__END__

=head1 SYNOPSIS

  my $episode = App::MP4Meta::Source::Data::TVEpisode->new(%data);

=attr cover

Path to cover imaage.

=attr genre

Genre.

=attr overview

Overview or description of TV episode.

=attr title

Episode title.

=attr year

Year of episodes original broadcast.

=method merge ($tv_episode)

Merges $tv_episode in $self, without overwriting $self.

=cut
