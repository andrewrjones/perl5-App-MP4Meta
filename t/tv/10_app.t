use Test::More tests => 6;
use App::Cmd::Tester;

use App::MP4Meta;

my $result;

# test no arguments
$result = test_app( App::MP4Meta => [qw(tv)] );
is( $result->stdout, '' );
is( $result->stderr, '', 'nothing sent to sderr' );
like( $result->error, qr/Error: too few arguments/ );

# test file does not exist
$result = test_app( App::MP4Meta => [qw(tv /does/not/exist.mp4)] );
is( $result->stdout, '' );
is( $result->stderr, '', 'nothing sent to sderr' );
like( $result->error, qr!Error: /does/not/exist.mp4 does not exist! );
