use 5.010;
use strict;
use warnings;

package App::MP4Meta::Film;

# ABSTRACT: Add metadata to a film

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use File::Spec '3.33';
use AtomicParsley::Command::Tags;

use App::MP4Meta::Source::Data::Film;

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($args);

    $self->{'media_type'} = 'Movie';

    return $self;
}

sub apply_meta {
    my ( $self, $path ) = @_;
    my %tags = (
        title => $self->{'title'},
        year  => $self->{'year'}
    );

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    unless ( $tags{title} ) {

        # parse the filename for the title, season and episode
        ( $tags{title}, $tags{year} ) = $self->_parse_filename($file);
        unless ( $tags{title} ) {
            return "Error: could not parse the filename for $path";
        }
    }

    my $film = App::MP4Meta::Source::Data::Film->new(
        genre => $self->{'genre'},
        cover => $self->{'cover'},
        year  => $self->{'year'},
    );
    unless ( _film_is_complete($film) ) {
        for my $source ( @{ $self->{'sources_objects'} } ) {
            say sprintf( "trying source '%s'", $source->name )
              if $self->{verbose};

            # merge new epiosde into previous
            $film->merge( $source->get_film( \%tags ) );

            # last if we have everything
            last
              if ( _film_is_complete($film) );
        }
    }

    # check what we have
    unless ( $film->overview ) {
        if (   $self->{'continue_without_any'}
            || $self->{'continue_without_overview'} )
        {
            say 'no overview found; continuing';
        }
        else {
            return sprintf( 'no overview found for %s', $tags{title} );
        }
    }

    my $apTags = AtomicParsley::Command::Tags->new(
        title       => $tags{title},
        description => $film->overview,
        genre       => $film->genre,
        year        => $film->year,
        artwork     => $film->cover,
        stik        => $self->{'media_type'},
    );

    say 'writing tags' if $self->{verbose};
    return $self->_write_tags( $path, $apTags );
}

# Parse the filename in order to get the film title. Returns the title.
sub _parse_filename {
    my ( $self, $file ) = @_;

    # strip suffix
    $file =~ s/\.m4v$//;

    # is there a year?
    my $year;
    if ( $file =~ s/(\d\d\d\d)$// ) {
        $year = $1;
        chop $file;
    }

    return ( $self->_clean_title($file), $year );
}

sub _film_is_complete {
    my $film = shift;
    return ( $film->overview && $film->genre && $film->year && $film->cover );
}

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::Film->new;
  $film->apply_meta( '/path/to/The_Truman_Show.m4v' );
  
=method apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=cut
