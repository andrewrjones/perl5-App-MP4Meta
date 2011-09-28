use 5.010;
use strict;
use warnings;

package App::MP4Meta::Command::film;

# ABSTRACT: Implement the film command

use App::MP4Meta -command;

sub usage_desc { "film %o [file ...]" }

sub opt_spec {
    return (
        [ "noreplace", "don't replace the file - creates temp file instead" ], );
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
