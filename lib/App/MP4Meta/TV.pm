use 5.010;
use strict;
use warnings;

package App::MP4Meta::TV;

# ABSTRACT: Add metadata to a TV Series

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use IMDB::Film '0.50';

use LWP::Simple '5.835';
use File::Spec '3.33';
use File::Temp '0.22', ();
use File::Copy;

use AtomicParsley::Command;
use AtomicParsley::Command::Tags;

sub apply_meta {
    my ( $self, $path ) = @_;

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    ...

}

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::TV->new;
  $film->apply_meta( '/path/to/THE_MIGHTY_BOOSH_S1E1.m4v' );
  
=method apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=cut
