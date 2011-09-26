use strict;
use warnings;

package App::MP4Meta::Command::film;
use App::MP4Meta -command;

sub execute {
    my ( $self, $opt, $args ) = @_;

    print "Foo";
}

1;
