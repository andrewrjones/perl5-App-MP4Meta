use 5.010;
use strict;
use warnings;

package App::MP4Meta::TV;

# ABSTRACT: Add metadata to a TV Series

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use File::Spec '3.33';
use HTML::TreeBuilder::XPath;
use AtomicParsley::Command::Tags;

# the wikipedia URL
use constant WIKIPEDIA_URL => 'http://en.wikipedia.org/w/index.php?title=%s';

# XPath expressions used to parse the wikipedia page
use constant XPATH_DESCRIPTIONS =>
  '//h3[%s]/following-sibling::table//td[@class="description" and @colspan]';
use constant XPATH_TITLES =>
'//h3[%s]/following-sibling::table//td[@class="summary" and @style="text-align: left;"]/b';
use constant XPATH_DATES =>
'//h3[%s]/following-sibling::table//td//span[@class="bday dtstart published updated"]';
use constant XPATH_IMAGE => '//table[@class="infobox vevent"]//img[1]/@src';

# a list of regexes to try to parse the file
my @file_regexes = (
    qr/^S(?<season>\d)-E(?<episode>\d)\s+-\s+(?<show>.*)$/,
    qr/^(?<show>.*)\s+S(?<season>\d\d)E(?<episode>\d\d)$/,
    qr/^(?<show>.*)\.S(?<season>\d\d)E(?<episode>\d\d)/,
    qr/^(?<show>.*) - S(?<season>\d\d?)E(?<episode>\d\d?)/i,
    qr/^(?<show>.*)-S(?<season>\d\d?)E(?<episode>\d\d?)/,
    qr/^(?<show>.*)_S(?<season>\d\d?)E(?<episode>\d\d?)/,
);

sub new {
    my $class = shift;
    my $args  = shift;

    my $self = $class->SUPER::new($args);

    $self->{'genre'}     = $args->{'genre'};
    $self->{'coverfile'} = $args->{'coverfile'};

    $self->{'media_type'} = 'TV Show';

    # cache for wikipedia pages
    $self->{'wikipedia_cache'} = {};

    return $self;
}

sub apply_meta {
    my ( $self, $path ) = @_;

    # get the file name
    my ( $volume, $directories, $file ) = File::Spec->splitpath($path);

    # parse the filename for the title, season and episode
    my ( $show_title, $season, $episode ) = $self->_parse_filename($file);
    unless ( $show_title && $season && $episode ) {
        return "Error: could not parse the filename for $path";
    }

    # get data from wikipedia
    my ( $episode_title, $episode_desc, $year, $cover_file ) =
      $self->_query_wikipedia( $show_title, $season, $episode );
    unless ( $episode_title && $episode_desc ) {
        return "Error: could not find details on wikipedia (for $path)";
    }

    my $genre = $self->{'genre'};
    unless ($genre) {
        my $imdb   = $self->_query_imdb($show_title);
        my @genres = @{ $imdb->genres };
        $genre = $genres[0];
    }

    $cover_file //= $self->{coverfile};
    unless ($cover_file) {
        my $imdb = $self->_query_imdb($show_title);
        $cover_file = $self->_get_cover_image( $imdb->cover );
    }

    my $tags = AtomicParsley::Command::Tags->new(
        artist       => $show_title,
        albumArtist  => $show_title,
        title        => $episode_title,
        album        => "$show_title, Season $season",
        tracknum     => $episode,
        TVShowName   => $show_title,
        TVEpisode    => $episode,
        TVEpisodeNum => $episode,
        TVSeasonNum  => $season,
        stik         => $self->{'media_type'},
        description  => $episode_desc,
        genre        => $genre,
        year         => $year,
        artwork      => $cover_file
    );

    return $self->_write_tags( $path, $tags );
}

# Parse the filename in order to get the series title the and season and episode number.
sub _parse_filename {
    my ( $self, $file ) = @_;

    # strip suffix
    $file =~ s/\.m4v$//;

    # see if we have a regex that matches
    for my $r (@file_regexes) {
        if ( $file =~ $r ) {
            my $show    = $+{show};
            my $season  = $+{season};
            my $episode = $+{episode};

            if ( $show && $season && $episode ) {

                return ( $self->_clean_title($show), int $season,
                    int $episode );
            }
        }
    }

    return;
}

# Queries wikipedia for the title and description of an episode
# of the show.
sub _query_wikipedia {
    my ( $self, $title, $season, $episode ) = @_;

    # firstly, lets try the page "House (season 1)"
    my $src = sprintf( WIKIPEDIA_URL, "$title (season $season)" );
    my $file = $self->_get_wikipedia_page($src);

    unless ($file) {
        $src = sprintf( WIKIPEDIA_URL, "$title (series $season)" );
        $file = $self->_get_wikipedia_page($src);
    }

    # parse the html file
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_file($file);

    # get the episode descriptions
    my @descriptions =
      $tree->findnodes_as_strings( sprintf( XPATH_DESCRIPTIONS, 1 ) );

    # get the episode titles
    my @titles = $tree->findnodes_as_strings( sprintf( XPATH_TITLES, 1 ) );

    # get the episode date
    my @dates = $tree->findnodes_as_strings( sprintf( XPATH_DATES, 1 ) );

    unless (@descriptions) {

        # OK, lets look for "List of House episodes"
        $src = sprintf( WIKIPEDIA_URL, "List of $title episodes" );
        $file = $self->_get_wikipedia_page($src);

        # parse the html file
        $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse_file($file);

        # get the episode descriptions
        @descriptions =
          $tree->findnodes_as_strings( sprintf( XPATH_DESCRIPTIONS, $season ) );

        # get the episode titles
        @titles =
          $tree->findnodes_as_strings( sprintf( XPATH_TITLES, $season ) );

        # get the episode date
        @dates = $tree->findnodes_as_strings( sprintf( XPATH_DATES, $season ) );

        unless (@descriptions) {

            # give up :-(
            return;
        }
    }

    # get the cover image
    my $cover_img_url = $tree->findvalue(XPATH_IMAGE);
    my $cover_img     = $self->_get_cover_image("http:$cover_img_url");

    # clean up description
    my $description = $descriptions[ $episode - 1 ];
    chop $description;
    $description =~ s/"/\\"/g;

    # get the year
    my $year;
    my $date = $dates[ $episode - 1 ];
    if ( $date =~ /^(\d{4})-\d{2}-\d{2}$/ ) {
        $year = $1;
    }

    # return the title and description
    return ( $titles[ $episode - 1 ], $description, $year, $cover_img );
}

# Gets a wikipedia page and saves it to a temporary file
# Returns the temp file name
sub _get_wikipedia_page {
    my ( $self, $url ) = @_;

    # first, check the cache
    if ( defined $self->{'wikipedia_cache'}->{$url} ) {
        return $self->{'wikipedia_cache'}->{$url};
    }

    # get the wikipedia url
    my $response = $self->{ua}->get($url);
    if ( !$response->is_success ) {
        return;
    }

    # create a temp file
    my $tmp = $self->_get_tempfile('html');

    # write html to temp file
    binmode($tmp, ":utf8");
    print $tmp $response->decoded_content;

    # cache temp file for future queries
    $self->{'wikipedia_cache'}->{$url} = $tmp->filename;

    return $tmp->filename;
}

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::TV->new({ genre => 'Comedy' });
  $film->apply_meta( '/path/to/THE_MIGHTY_BOOSH_S1E1.m4v' );
  
=method apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=cut
