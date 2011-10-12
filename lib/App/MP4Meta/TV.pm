use 5.010;
use strict;
use warnings;

package App::MP4Meta::TV;

# ABSTRACT: Add metadata to a TV Series

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use LWP::Simple '5.835';
use File::Spec '3.33';
use File::Temp '0.22', ();
use File::Copy;

use AtomicParsley::Command;
use AtomicParsley::Command::Tags;

# a list of regexes to try to parse the file
my @file_regexes = (
    qr/^S(?<season>\d)-E(?<episode>\d)\s+-\s+(?<show>.*)$/,
    qr/^(?<show>.*)\s+S(?<season>\d\d)E(?<episode>\d\d)$/,
    qr/^(?<show>.*)\.S(?<season>\d\d)E(?<episode>\d\d)/,
    qr/^(?<show>.*) - S(?<season>\d\d?)E(?<episode>\d\d?)/i,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)/,
    qr/^(?<show>.*)_S(?<season>\d\d?)E(?<episode>\d\d?)/,
);

sub apply_meta {
    my ( $self, $path ) = @_;

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    ...

}

# Parse the filename in order to get the series title the and season and episode number.
sub _parse_filename {
    my ( $self, $file ) = @_;

    # strip suffix
    $file =~ s/\.m4v$//;

    # see if we have a regex that matches
    for my $r (@file_regexes) {
        if ( $file =~ $r ) {
            my $show    = $+{show};
            my $season  = $+{season};
            my $episode = $+{episode};

            if ( $show && $season && $episode ) {
                $show =~ s/(-|_)/ /g;
                return ( $show, int $season, int $episode );
            }
        }
    }

    return;
}

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::TV->new;
  $film->apply_meta( '/path/to/THE_MIGHTY_BOOSH_S1E1.m4v' );
  
=method apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=cut
