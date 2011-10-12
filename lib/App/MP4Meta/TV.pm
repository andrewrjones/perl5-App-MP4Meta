use 5.010;
use strict;
use warnings;

package App::MP4Meta::TV;

# ABSTRACT: Add metadata to a TV Series

use App::MP4Meta::Base;
our @ISA = 'App::MP4Meta::Base';

use File::Spec '3.33';
use File::Temp '0.22', ();
use File::Copy;
require LWP::UserAgent;
use HTML::TreeBuilder::XPath;

use AtomicParsley::Command;
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

    $self->{'genre'} = $args->{'genre'};

    $self->{'media_type'} = 'TV Show';

    # LWP::UserAgent
    $self->{'ua'} = LWP::UserAgent->new;

    # cache for wikipedia pages
    $self->{'wikipedia_cache'} = {};

    # cache for cover images
    $self->{'cover_img_cache'} = {};

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
        genre        => $self->{'genre'},
        year         => $year,
        artwork      => $cover_file
    );

    my $tempfile = $self->{ap}->write_tags( $path, $tags, !$self->{noreplace} );

    if ( !$self->{ap}->{success} ) {
        return $self->{ap}->{'stdout_buf'}[0] // $self->{ap}->{'full_buf'}[0];
    }

    if ( !$tempfile ) {
        return "Error writing to file";
    }
    return;
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
                $show =~ s/(-|_)/ /g;
                return ( $show, int $season, int $episode );
            }
        }
    }

    return;
}

# Queries wikipedia for the title and description of an episode
# of the show.
sub _query_wikipedia {
    my ( $self, $title, $season, $episode ) = @_;

    # firstly, lets look for "List of House episodes"
    my $src = sprintf( WIKIPEDIA_URL, "List of $title episodes" );
    my $file = $self->_get_wikipedia_page($src);

    # parse the html file
    my $tree = HTML::TreeBuilder::XPath->new;
    $tree->parse_file($file);

    # get the episode descriptions
    my @descriptions =
      $tree->findnodes_as_strings( sprintf( XPATH_DESCRIPTIONS, $season ) );

    # get the episode titles
    my @titles =
      $tree->findnodes_as_strings( sprintf( XPATH_TITLES, $season ) );

    # get the episode date
    my @dates = $tree->findnodes_as_strings( sprintf( XPATH_DATES, $season ) );

    unless (@descriptions) {

        # OK, lets try the page "House (season 1)"
        $src = sprintf( WIKIPEDIA_URL, "$title (season $season)" );
        $file = $self->_get_wikipedia_page($src);

        # parse the html file
        $tree = HTML::TreeBuilder::XPath->new;
        $tree->parse_file($file);

        # get the episode descriptions
        @descriptions =
          $tree->findnodes_as_strings( sprintf( XPATH_DESCRIPTIONS, 1 ) );

        # get the episode titles
        @titles = $tree->findnodes_as_strings( sprintf( XPATH_TITLES, 1 ) );

        # get the episode date
        @dates = $tree->findnodes_as_strings( sprintf( XPATH_DATES, 1 ) );

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
    my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => '.html' );
    push @{ $self->{tmp_files} }, $tmp->filename;    # so it gets removed later

    # write html to temp file
    print $tmp $response->decoded_content;

    # cache temp file for future queries
    $self->{'wikipedia_cache'}->{$url} = $tmp->filename;

    return $tmp->filename;
}

sub _get_cover_image {
    my ( $self, $url ) = @_;

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
        my $tmp = File::Temp->new( UNLINK => 0, SUFFIX => ".$suffix" );
        push @{ $self->{tmp_files} }, $tmp->filename; # so it gets removed later

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

1;

=head1 SYNOPSIS

  my $film = App::MP4Meta::TV->new;
  $film->apply_meta( '/path/to/THE_MIGHTY_BOOSH_S1E1.m4v' );
  
=method apply_meta( $path )

Apply metadata to the file at this path.

Returns undef if success; string if error.

=cut
