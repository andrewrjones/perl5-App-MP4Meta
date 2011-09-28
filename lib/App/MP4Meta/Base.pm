use 5.010;
use strict;
use warnings;

package App::MP4Meta::Base;

# ABSTRACT: Base class.

use AtomicParsley::Command;

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # the path to AtomicParsley
    $self->{'ap'} = AtomicParsley::Command->new( { ap => $args->{'ap'} } );

    # if true, replace file
    $self->{'noreplace'} = $args->{'noreplace'};

    # stores tmp files which we clean up later
    $self->{'tmp_files'} = ();

    bless( $self, $class );
    return $self;
}

sub DESTROY {
    my $self = shift;

    # remove all tmp files
    for my $f ( @{ $self->{tmp_files} } ) {
        unlink $f;
    }
}

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::Base->new( ap => 'path/to/ap' );
  $film->apply_meta( '/path/to/The_Truman_Show.m4v' );
  
=method new( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=method parse_filename( $file )

Parse the filename in order to get the film title. Returns the title.

=method query_imdb( $title )

Make a query to imdb and get the film data.

Returns undef if we couldn't find the film.

Returns an IMDB::Film object.

=method get_cover_image( $cover_url )

Gets the cover image and stores in a tmp file

=cut
