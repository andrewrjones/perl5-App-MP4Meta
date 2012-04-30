use 5.010;
use strict;
use warnings;

package App::MP4Meta::Source::Data::Film;

# ABSTRACT: Contains data for a film.

use App::MP4Meta::Source::Data::Base;
our @ISA = 'App::MP4Meta::Source::Data::Base';

1;

__END__

=head1 SYNOPSIS

  my $episode = App::MP4Meta::Source::Data::Film->new(%data);

=cut
