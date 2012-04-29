use 5.010;
use strict;
use warnings;

package App::MP4Meta::Command::tv;

# ABSTRACT: Apply metadata to a TV Series. Parses the filename in order to get the shows title and its season and episode number.

use App::MP4Meta -command;

use Try::Tiny;

#use Term::ProgressBar::Simple;

=head1 SYNOPSIS

  mp4meta tv THE_MIGHTY_BOOSH_S1E1.m4v THE_MIGHTY_BOOSH_S1E2.m4v

  mp4meta tv --noreplace 24.S01E01.m4v

=head1 DESCRIPTION

This command applies metadata to one or more TV Series. It parses the filename in order to get the shows title and its season and episode number.

It gets the TV Series metadata by querying various sources (see below). It then uses AtomicParsley to apply the metadata to the file.

If it can not find the TV Series on any of the sources, by default it will not apply any metadata. If you wan't it to apply what it can, pass the C<--withoutany> option.

By default, it will apply the metadata to the existing file. If you want it to write to a temporary file and leave the existing file untouched, provide the C<--noreplace> option.

=cut

sub usage_desc { "tv %o [file ...]" }

sub abstract {
'Apply metadata to a TV Series. Parses the filename in order to get the shows title and its season and episode number.';
}

sub opt_spec {
    return (
        [ "genre=s",     "The genre of the TV Show" ],
        [ "coverfile=s", "The location of the cover image" ],
        [
            "sources=s@",
            "The sources to search",
            { default => [qw/TVDB IMDB/] }
        ],
        [ "title=s",   "The title of the TV Show" ],
        [ "series=s",  "The series number" ],
        [ "episode=s", "The episode number" ],
        [ "noreplace", "Don't replace the file - creates a temp file instead" ],
        [ "verbose",   "Print verbosely" ],
        [
            "withoutany",
"Continue to process even if we can not find any information on the internet"
        ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;

    # we need at least one file to work with
    $self->usage_error("too few arguments") unless @$args;

    # TODO: check we have a source

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
            noreplace            => $opt->{noreplace},
            genre                => $opt->{genre},
            sources              => $opt->{sources},
            title                => $opt->{title},
            coverfile            => $opt->{coverfile},
            verbose              => $opt->{verbose},
            continue_without_any => $opt->{withoutany},
        }
    );

    say sprintf( 'processing %d files', scalar @$args ) if $opt->{verbose};

    for my $file (@$args) {
        say "processing $file" if $opt->{verbose};
        my $error;
        try {
            $error = $tv->apply_meta($file);
        }
        catch {
            $error = "Error applying meta to $file: $_";
        }
        finally {
            say $error if $error;
        };
    }

    say 'done' if $opt->{verbose};
}

1;
