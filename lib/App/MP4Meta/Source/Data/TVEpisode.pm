use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::Data::TVEpisode;

# ABSTRACT: Contains data for a TV Episode.

use App::MP4Meta::Source::Data::Base;
our @ISA = 'App::MP4Meta::Source::Data::Base';

use Object::Tiny qw(
  show_title
);

1;

__END__

=head1 SYNOPSIS

  my $episode = App::MP4Meta::Source::Data::TVEpisode->new(%data);

=attr show_title

Title of the show.

=cut
