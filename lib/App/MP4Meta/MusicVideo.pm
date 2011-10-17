use 5.010;
use strict;
use warnings;

package App::MP4Meta::MusicVideo;

# ABSTRACT: Add metadata to a music video

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use File::Spec '3.33';
use AtomicParsley::Command::Tags;

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($args);

    $self->{'genre'}     = $args->{'genre'};
    $self->{'title'}     = $args->{'title'};
    $self->{'coverfile'} = $args->{'coverfile'};

    $self->{'media_type'} = 'Music Video';

    return $self;
}

sub apply_meta {
    my ( $self, $path ) = @_;

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    # parse the filename for the film title and optional year
    my ( $artist, $title ) = $self->_parse_filename($file);

    my $tags = AtomicParsley::Command::Tags->new(
        artist      => $artist,
        albumArtist => $artist,
        title       => $self->{'title'} // $title,
        stik        => $self->{'media_type'},
        genre       => $self->{'genre'},
        artwork     => $self->{'coverfile'}
    );

    return $self->_write_tags( $path, $tags );
}

# Parse the filename in order to get the film title. Returns the title.
sub _parse_filename {
    my ( $self, $file ) = @_;

    # strip suffix
    $file =~ s/\.m4v$//;

    if ( $file =~ /^(.*) - (.*)$/ ) {
        return ( $self->_clean_title($1), $self->_clean_title($2) );
    }

    return;
}

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::MusicVideo->new;
  $film->apply_meta( '/path/to/Michael Jackson vs Prodigy - Bille Girl' );
  
=method apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=cut
