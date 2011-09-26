use Test::More tests => 3;
use App::Cmd::Tester;

use App::MP4Meta;

my $result = test_app( App::MP4Meta => [qw(film)] );
is( $result->stdout, 'Foo' );

is( $result->stderr, '', 'nothing sent to sderr' );

is( $result->error, undef, 'threw no exceptions' );
