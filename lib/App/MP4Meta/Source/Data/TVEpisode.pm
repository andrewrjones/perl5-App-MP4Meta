use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::Data::TVEpisode;

# ABSTRACT: Contains data for a TV Episode.

use App::MP4Meta::Source::Data::Base;
our @ISA = 'App::MP4Meta::Source::Data::Base';

1;

__END__

=head1 SYNOPSIS

  my $episode = App::MP4Meta::Source::Data::TVEpisode->new(%data);

=cut
