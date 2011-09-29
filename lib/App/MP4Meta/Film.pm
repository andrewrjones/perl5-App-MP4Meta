use 5.010;
use strict;
use warnings;

package App::MP4Meta::Film;

# ABSTRACT: Add metadata to a film

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

    # parse the filename for the film title and optional year
    my ( $title, $year ) = $self->_parse_filename($file);

    # get data from IMDB
    my $imdb = $self->_query_imdb( $title, $year );
    unless ($imdb) {
        return "Error: could not find '$title' on the IMDB (for $path)";
    }

    # try and get a cover file
    my $cover_file;
    if ( $imdb->cover ) {
        $cover_file = $self->_get_cover_image( $imdb->cover );
    }

    my @genres = @{ $imdb->genres };
    my $genre  = $genres[0];

    my $tags = AtomicParsley::Command::Tags->new(
        title       => $imdb->title,
        description => $imdb->storyline,
        genre       => $genre,
        year        => $imdb->year,
        artwork     => $cover_file
    );

    my $tempfile = $self->{ap}->write_tags( $path, $tags, $self->{noreplace} );
}

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

    # make space
    $file =~ s/(-|_)/ /g;

    return ( $file, $year );
}

sub _query_imdb {
    my ( $self, $title, $year ) = @_;

    my $imdb = IMDB::Film->new( crit => $title, year => $year );

    if ( $imdb->status ) {
        return $imdb;
    }
    return;
}

sub _get_cover_image {
    my ( $self, $cover_url ) = @_;

    if ( $cover_url =~ m/\.(jpg|png)$/ ) {
        my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => ".$1" );

        # save the tmp file for later
        push @{ $self->{tmp_files} }, $tmp->filename;

        # get the cover image
        getstore( $cover_url, $tmp->filename );

        # return cover file
        return $tmp->filename;
    }
    else {

        # can't use cover
        return;
    }
}

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::Film->new;
  $film->apply_meta( '/path/to/The_Truman_Show.m4v' );
  
=method apply_meta( $path )

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
