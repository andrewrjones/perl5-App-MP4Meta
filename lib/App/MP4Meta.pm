use strict;
use warnings;

package App::MP4Meta;

# ABSTRACT: Apply iTunes-like metadata to an mp4 file.

use App::Cmd::Setup -app;

=head1 DESCRIPTION

The C<mp4meta> command applies iTunes-like metadata to an mp4 file. The metadata is obtained by parsing the filename and searching the Internet to find its title, description and cover image, amongst others.

Currently, only the C<film> command has been implemented. TV Series support will be added soon.

=head2 film

The C<film> command parses the filename and searches the IMDB for film metadata. See L<App::MP4Meta::Command::film> for more information.

=head1 TODO

=for :list
* Implement C<tv> command for TV Series

=cut

1;
