use 5.010;
use strict;
use warnings;

package App::MP4Meta::Command::tv;

# ABSTRACT: Apply metadata to a TV Series. Parses the filename in order to get the shows title and its season and episode number.

use App::MP4Meta -command;

=head1 SYNOPSIS

  mp4meta tv THE_MIGHTY_BOOSH_S1E1.m4v THE_MIGHTY_BOOSH_S1E2.m4v
  
  mp4meta film --noreplace 24.S01E01.m4v

This command applies metadata to one or more TV Series. It parses the filename in order to get the shows title and its season and episode number.

It gets the TV Series metadata by querying Wikipedia. It then uses AtomicParsley to apply the metadata to the file.

By default, it will apply the metadata to the existing file. If you want it to write to a temporary file and leave the existing file untouched, provide the C<--noreplace> option.

=cut

sub usage_desc { "tv %o [file ...]" }

sub abstract {
'Apply metadata to a TV Series. Parses the filename in order to get the shows title and its season and episode number.';
}

sub opt_spec {
    return (
        [ "genre",     "The genre of the TV Show" ],
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

    require App::MP4Meta::TV;
    my $tv = App::MP4Meta::TV->new(
        {
            noreplace => $opt->{noreplace},
            genre     => $opt->{genre},
        }
    );

    for my $file (@$args) {
        my $error = $tv->apply_meta($file);
        say $error if $error;
    }
}

1;
