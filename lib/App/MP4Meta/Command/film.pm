use 5.010;
use strict;
use warnings;

package App::MP4Meta::Command::film;

# ABSTRACT: Apply metadata to a film. Parses the filename in order to get the films title and (optionally) year.

use App::MP4Meta -command;

=head1 SYNOPSIS

  mp4meta film PULP_FICTION.mp4 "The Truman Show.m4v"
  
  mp4meta film --noreplace THE-ITALIAN-JOB-2003.m4v

This command applies metadata to one or more films. It parses the filename in order to get the films title and (optionally) year.

It gets the films metadata by querying the IMDB. It then uses AtomicParsley to apply the metadata to the file.

By default, it will apply the metadata to the existing file. If you want it to write to a temporary file and leave the existing file untouched, provide the "--noreplace" option.

=cut

sub usage_desc { "film %o [file ...]" }

sub abstract {
'Apply metadata to a film. Parses the filename in order to get the films title and (optionally) year.';
}

sub opt_spec {
    return (
        [ "noreplace", "Don't replace the file - creates a temp file instead" ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    # we need at least one file to work with
    $self->usage_error("too few arguments") unless @$args;

    # check each file
    for my $f (@$args) {
        unless ( -e $f ) {
            $self->usage_error("$f does not exist");
        }
        unless ( -r $f ) {
            $self->usage_error("can not read $f");
        }

        # TODO: is $f an mp4?
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    require App::MP4Meta::Film;
    my $film = App::MP4Meta::Film->new( { noreplace => $opt->{noreplace}, } );

    for my $file (@$args) {
        my $error = $film->apply_meta($file);
        say $error if $error;
    }
}

1;
