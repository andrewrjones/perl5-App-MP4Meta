use 5.010;
use strict;
use warnings;

package App::MP4Meta::Base;

# ABSTRACT: Base class.

use File::Temp '0.22', ();

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

sub _write_tags {
    my ( $self, $path, $tags ) = @_;

    my $tempfile = $self->{ap}->write_tags( $path, $tags, !$self->{noreplace} );

    if ( !$self->{ap}->{success} ) {
        return $self->{ap}->{'stdout_buf'}[0] // $self->{ap}->{'full_buf'}[0];
    }

    if ( !$tempfile ) {
        return "Error writing to file";
    }

    return;
}

# Converts 'THE_OFFICE' to 'The Office'
sub _clean_title {
    my ( $self, $title ) = @_;

    $title =~ s/(-|_)/ /g;
    $title = lc($title);
    $title = join ' ', map( { ucfirst() } split /\s/, $title );

    return $title;
}

sub _get_tempfile {
    my ( $self, $suffix ) = @_;

    $suffix = $suffix // 'tmp';

    my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => ".$suffix" );

    # save the tmp file for later
    push @{ $self->{tmp_files} }, $tmp->filename;

    return $tmp;
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
