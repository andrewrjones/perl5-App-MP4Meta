use 5.010;
use strict;
use warnings;

package App::MP4Meta::Base;

# ABSTRACT: Base class. Contains common functionality.

use File::Temp '0.22', ();
use File::Copy;
use IMDB::Film '0.50';
require LWP::UserAgent;

use AtomicParsley::Command;

sub new {
    my $class = shift;
    my $args  = shift;
    my $self  = {};

    # the path to AtomicParsley
    $self->{'ap'} = AtomicParsley::Command->new( { ap => $args->{'ap'} } );

    # LWP::UserAgent
    $self->{'ua'} = LWP::UserAgent->new;

    # if true, replace file
    $self->{'noreplace'} = $args->{'noreplace'};

    # stores tmp files which we clean up later
    $self->{'tmp_files'} = ();

    # cache for IMDB objects
    $self->{'imdb_cache'} = {};

    # cache for cover images
    $self->{'cover_img_cache'} = {};

    bless( $self, $class );
    return $self;
}

# Calls AtomicParsley and writes the tags to the file
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

# Make a query to imdb
# Returns undef if we couldn't find the query.
# Returns an IMDB::Film object.
sub _query_imdb {
    my ( $self, $title, $year ) = @_;

    # first, check the cache
    my $key = $title;
    $key .= $year if $year;
    if ( defined $self->{'imdb_cache'}->{$key} ) {
        return $self->{'imdb_cache'}->{$key};
    }

    my $imdb = IMDB::Film->new( crit => $title, year => $year );

    if ( $imdb->status ) {

        # cache IMDB object for future queries
        $self->{'imdb_cache'}->{$key} = $imdb;

        return $imdb;
    }
    return;
}

# Gets the cover image and stores in a tmp file
sub _get_cover_image {
    my ( $self, $url ) = @_;

    return unless $url;

    if ( $url =~ m/\.(jpg|png)$/ ) {
        my $suffix = $1;

        # first, check the cache
        if ( defined $self->{'cover_img_cache'}->{$url} ) {
            return $self->{'cover_img_cache'}->{$url};
        }

        # get the image
        my $response = $self->{ua}->get($url);
        if ( !$response->is_success ) {
            return;
        }

        # create a temp file
        my $tmp = $self->_get_tempfile($suffix);

        # write img to temp file
        binmode $tmp;
        print $tmp $response->decoded_content;

        # cache temp file for future queries
        $self->{'cover_img_cache'}->{$url} = $tmp->filename;

        return $tmp->filename;
    }
    else {

        # can't use cover
        return;
    }
}

# Converts 'THE_OFFICE' to 'The Office'
sub _clean_title {
    my ( $self, $title ) = @_;

    $title =~ s/(-|_)/ /g;
    $title = lc($title);
    $title = join ' ', map( { ucfirst() } split /\s/, $title );

    return $title;
}

# Returns a File::Temp object
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
