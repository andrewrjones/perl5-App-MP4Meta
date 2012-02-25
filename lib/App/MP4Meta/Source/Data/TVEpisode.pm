use strict;
use warnings;

package App::MP4Meta::Source::Data::TVEpisode;

# ABSTRACT: Contains data for a TV Episode.

use Object::Tiny qw(
    cover
    genre
    overview
    title
    year
);

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

Year of episodes original broadcast

=cut