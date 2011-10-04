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
  
=method new( %args )

Create new object. Takes the following arguments:

=for :list
* ap - Path to the AtomicParsley command. Optional.
* noreplace - If true, do not replace file, but save to temp instead
