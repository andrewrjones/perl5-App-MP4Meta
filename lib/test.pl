#!/usr/bin/perl
use strict;
use warnings;
use FindBin;                 # locate this script
use lib "$FindBin::Bin";
use App::MP4Meta;
use App::MP4Meta::TV;

my $tv = App::MP4Meta::TV->new({ sources => [qw{TVDB}] });
$tv->apply_meta( '/Volumes/Media3/TV Shows/House of Cards (US)/S01E01.mp4');
